
const db = require('../config/database');

// Pemeriksaan tambahan: hanya Admin yang boleh mengelola jadwal.
function ensureAdmin(req, res) {
  if (!req.user || req.user.role !== 'Admin') {
    res.status(403).json({
      message: 'Hanya Admin yang dapat mengelola jadwal.',
    });

    return false;
  }

  return true;
}

// Validasi format waktu HH:mm.
function isValidTime(time) {
  return typeof time === 'string' &&
    /^([01]\d|2[0-3]):[0-5]\d$/.test(time);
}

// Validasi data jadwal.
function validateSchedule(data) {
  const {
    subject,
    weekday,
    start_time,
    end_time,
    reminder_minutes,
  } = data;

  if (
    typeof subject !== 'string' ||
    !subject.trim()
  ) {
    return 'Nama mata pelajaran wajib diisi.';
  }

  if (
    !Number.isInteger(weekday) ||
    weekday < 1 ||
    weekday > 7
  ) {
    return 'Hari harus berupa angka 1 sampai 7.';
  }

  if (!isValidTime(start_time) || !isValidTime(end_time)) {
    return 'Format waktu harus HH:mm.';
  }

  if (start_time >= end_time) {
    return 'Waktu selesai harus setelah waktu mulai.';
  }

  if (
    !Number.isInteger(reminder_minutes) ||
    reminder_minutes < 0
  ) {
    return 'Waktu pengingat harus berupa angka nol atau lebih.';
  }

  return null;
}

// Memeriksa apakah kelas tersedia.
function findClass(classId) {
  return db.prepare(`
    SELECT id, class_name, major, cohort_year
    FROM academic_classes
    WHERE id = ?
  `).get(classId);
}

// Mengambil jadwal.
function getSchedules(req, res) {
  try {
    let schedules;

    if (req.user.role === 'Admin') {
      // Admin dapat melihat seluruh jadwal.
      schedules = db.prepare(`
        SELECT
          s.*,
          ac.class_name,
          ac.major,
          ac.cohort_year,
          creator.email AS created_by_email
        FROM schedules s
        LEFT JOIN academic_classes ac
          ON ac.id = s.class_id
        LEFT JOIN users creator
          ON creator.id = s.user_id
        ORDER BY s.weekday ASC, s.start_time ASC
      `).all();
    } else if (req.user.role === 'Murid') {
      // Mahasiswa melihat jadwal kelasnya.
      // Jadwal lama miliknya sendiri tetap ditampilkan.
      schedules = db.prepare(`
        SELECT
          s.*,
          ac.class_name,
          ac.major,
          ac.cohort_year
        FROM schedules s
        LEFT JOIN academic_classes ac
          ON ac.id = s.class_id
        WHERE
          s.class_id = (
            SELECT class_id
            FROM users
            WHERE id = ?
          )
          OR (
            s.class_id IS NULL
            AND s.user_id = ?
          )
        ORDER BY s.weekday ASC, s.start_time ASC
      `).all(req.user.id, req.user.id);
    } else {
      // Untuk Guru, pertahankan akses jadwal miliknya
      // seperti perilaku backend sebelumnya.
      schedules = db.prepare(`
        SELECT
          s.*,
          ac.class_name,
          ac.major,
          ac.cohort_year
        FROM schedules s
        LEFT JOIN academic_classes ac
          ON ac.id = s.class_id
        WHERE s.user_id = ?
        ORDER BY s.weekday ASC, s.start_time ASC
      `).all(req.user.id);
    }

    return res.json({
      message: 'Data jadwal berhasil diambil.',
      total: schedules.length,
      data: schedules,
    });
  } catch (error) {
    console.error('Get schedules error:', error);

    return res.status(500).json({
      message: 'Gagal mengambil data jadwal.',
    });
  }
}

// Admin membuat jadwal untuk satu kelas.
function createSchedule(req, res) {
  if (!ensureAdmin(req, res)) return;

  try {
    const {
      subject,
      weekday,
      start_time,
      end_time,
      room = '',
      lecturer = '',
      notes = '',
      reminder_enabled = false,
      reminder_minutes = 15,
      class_id,
    } = req.body;

    const errorMessage = validateSchedule({
      subject,
      weekday,
      start_time,
      end_time,
      reminder_minutes,
    });

    if (errorMessage) {
      return res.status(400).json({
        message: errorMessage,
      });
    }

    if (
      typeof reminder_enabled !== 'boolean' &&
      reminder_enabled !== 0 &&
      reminder_enabled !== 1
    ) {
      return res.status(400).json({
        message: 'reminder_enabled harus berupa boolean.',
      });
    }

    if (
      typeof room !== 'string' ||
      typeof lecturer !== 'string' ||
      typeof notes !== 'string'
    ) {
      return res.status(400).json({
        message: 'Room, lecturer, dan notes harus berupa teks.',
      });
    }

    const targetClassId = Number(class_id);

    if (
      class_id === undefined ||
      !Number.isInteger(targetClassId) ||
      targetClassId <= 0
    ) {
      return res.status(400).json({
        message: 'class_id kelas akademik wajib diisi.',
      });
    }

    const targetClass = findClass(targetClassId);

    if (!targetClass) {
      return res.status(404).json({
        message: 'Kelas akademik tidak ditemukan.',
      });
    }

    // user_id mencatat Admin yang membuat jadwal.
    // class_id menentukan mahasiswa yang menerima jadwal.
    const result = db.prepare(`
      INSERT INTO schedules (
        user_id,
        class_id,
        subject,
        weekday,
        start_time,
        end_time,
        room,
        lecturer,
        notes,
        reminder_enabled,
        reminder_minutes
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      req.user.id,
      targetClassId,
      subject.trim(),
      weekday,
      start_time,
      end_time,
      room.trim(),
      lecturer.trim(),
      notes.trim(),
      reminder_enabled ? 1 : 0,
      reminder_minutes
    );

    const newSchedule = db.prepare(`
      SELECT
        s.*,
        ac.class_name,
        ac.major,
        ac.cohort_year
      FROM schedules s
      LEFT JOIN academic_classes ac
        ON ac.id = s.class_id
      WHERE s.id = ?
    `).get(result.lastInsertRowid);

    return res.status(201).json({
      message: 'Jadwal kelas berhasil ditambahkan.',
      data: newSchedule,
    });
  } catch (error) {
    console.error('Create schedule error:', error);

    return res.status(500).json({
      message: 'Gagal menambahkan jadwal.',
    });
  }
}

// Admin mengubah jadwal.
function updateSchedule(req, res) {
  if (!ensureAdmin(req, res)) return;

  try {
    const scheduleId = Number(req.params.id);

    if (!Number.isInteger(scheduleId) || scheduleId <= 0) {
      return res.status(400).json({
        message: 'ID jadwal tidak valid.',
      });
    }

    const existing = db.prepare(`
      SELECT *
      FROM schedules
      WHERE id = ?
    `).get(scheduleId);

    if (!existing) {
      return res.status(404).json({
        message: 'Jadwal tidak ditemukan.',
      });
    }

    const {
      subject,
      weekday,
      start_time,
      end_time,
      room = '',
      lecturer = '',
      notes = '',
      reminder_enabled = false,
      reminder_minutes = 15,
      class_id,
    } = req.body;

    const errorMessage = validateSchedule({
      subject,
      weekday,
      start_time,
      end_time,
      reminder_minutes,
    });

    if (errorMessage) {
      return res.status(400).json({
        message: errorMessage,
      });
    }

    if (
      typeof reminder_enabled !== 'boolean' &&
      reminder_enabled !== 0 &&
      reminder_enabled !== 1
    ) {
      return res.status(400).json({
        message: 'reminder_enabled harus berupa boolean.',
      });
    }

    if (
      typeof room !== 'string' ||
      typeof lecturer !== 'string' ||
      typeof notes !== 'string'
    ) {
      return res.status(400).json({
        message: 'Room, lecturer, dan notes harus berupa teks.',
      });
    }

    // Jika class_id tidak dikirim, pertahankan kelas sebelumnya.
    const targetClassId = class_id === undefined
      ? existing.class_id
      : Number(class_id);

    if (
      targetClassId !== null &&
      (
        !Number.isInteger(targetClassId) ||
        targetClassId <= 0
      )
    ) {
      return res.status(400).json({
        message: 'class_id tidak valid.',
      });
    }

    if (
      targetClassId !== null &&
      !findClass(targetClassId)
    ) {
      return res.status(404).json({
        message: 'Kelas akademik tidak ditemukan.',
      });
    }

    db.prepare(`
      UPDATE schedules
      SET
        class_id = ?,
        subject = ?,
        weekday = ?,
        start_time = ?,
        end_time = ?,
        room = ?,
        lecturer = ?,
        notes = ?,
        reminder_enabled = ?,
        reminder_minutes = ?,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `).run(
      targetClassId,
      subject.trim(),
      weekday,
      start_time,
      end_time,
      room.trim(),
      lecturer.trim(),
      notes.trim(),
      reminder_enabled ? 1 : 0,
      reminder_minutes,
      scheduleId
    );

    const updatedSchedule = db.prepare(`
      SELECT
        s.*,
        ac.class_name,
        ac.major,
        ac.cohort_year
      FROM schedules s
      LEFT JOIN academic_classes ac
        ON ac.id = s.class_id
      WHERE s.id = ?
    `).get(scheduleId);

    return res.json({
      message: 'Jadwal berhasil diperbarui.',
      data: updatedSchedule,
    });
  } catch (error) {
    console.error('Update schedule error:', error);

    return res.status(500).json({
      message: 'Gagal memperbarui jadwal.',
    });
  }
}

// Admin menghapus jadwal.
function deleteSchedule(req, res) {
  if (!ensureAdmin(req, res)) return;

  try {
    const scheduleId = Number(req.params.id);

    if (!Number.isInteger(scheduleId) || scheduleId <= 0) {
      return res.status(400).json({
        message: 'ID jadwal tidak valid.',
      });
    }

    const existing = db.prepare(`
      SELECT id
      FROM schedules
      WHERE id = ?
    `).get(scheduleId);

    if (!existing) {
      return res.status(404).json({
        message: 'Jadwal tidak ditemukan.',
      });
    }

    db.prepare(`
      DELETE FROM schedules
      WHERE id = ?
    `).run(scheduleId);

    return res.json({
      message: 'Jadwal berhasil dihapus.',
    });
  } catch (error) {
    console.error('Delete schedule error:', error);

    return res.status(500).json({
      message: 'Gagal menghapus jadwal.',
    });
  }
}

module.exports = {
  getSchedules,
  createSchedule,
  updateSchedule,
  deleteSchedule,
};
