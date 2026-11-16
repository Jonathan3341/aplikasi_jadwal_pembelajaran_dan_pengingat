
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

// Memeriksa apakah akun Guru tersedia.
function findTeacher(teacherId) {
  return db.prepare(`
    SELECT id, name, email, major
    FROM users
    WHERE id = ?
      AND role = 'Guru'
  `).get(teacherId);
}

// Mengambil jadwal.
function getSchedules(req, res) {
  try {
    let schedules = [];

    if (req.user.role === 'Admin') {
      // Admin dapat melihat seluruh jadwal.
      schedules = db.prepare(`
        SELECT
          s.*,
          ac.class_name,
          ac.major,
          ac.cohort_year,
          creator.email AS created_by_email,
          teacher.name AS teacher_name,
          teacher.email AS teacher_email
        FROM schedules s
        LEFT JOIN academic_classes ac
          ON ac.id = s.class_id
        LEFT JOIN users creator
          ON creator.id = s.user_id
        LEFT JOIN users teacher
          ON teacher.id = s.teacher_id
        ORDER BY s.weekday ASC, s.start_time ASC
      `).all();

    } else if (req.user.role === 'Guru') {
      // Guru hanya melihat jadwal yang ditugaskan kepadanya.
      schedules = db.prepare(`
        SELECT
          s.*,
          ac.class_name,
          ac.major,
          ac.cohort_year,
          teacher.name AS teacher_name
        FROM schedules s
        LEFT JOIN academic_classes ac
          ON ac.id = s.class_id
        LEFT JOIN users teacher
          ON teacher.id = s.teacher_id
        WHERE s.teacher_id = ?
        ORDER BY s.weekday ASC, s.start_time ASC
      `).all(req.user.id);

    } else if (req.user.role === 'Murid') {
      // Ambil kelas tempat Murid terdaftar.
      const student = db.prepare(`
        SELECT class_id
        FROM users
        WHERE id = ?
          AND role = 'Murid'
      `).get(req.user.id);

      // Jika Murid belum memiliki kelas, tampilkan jadwal kosong.
      if (student && student.class_id) {
        schedules = db.prepare(`
          SELECT
            s.*,
            ac.class_name,
            ac.major,
            ac.cohort_year,
            teacher.name AS teacher_name
          FROM schedules s
          LEFT JOIN academic_classes ac
            ON ac.id = s.class_id
          LEFT JOIN users teacher
            ON teacher.id = s.teacher_id
          WHERE s.class_id = ?
          ORDER BY s.weekday ASC, s.start_time ASC
        `).all(student.class_id);
      }

    } else {
      return res.status(403).json({
        message: 'Anda tidak memiliki akses untuk melihat jadwal.',
      });
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
    teacher_id,
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

   // Validasi kelas.
   const targetClassId = Number(class_id);

   if (
     class_id === undefined ||
     !Number.isInteger(targetClassId) ||
     targetClassId <= 0
   ) {
     return res.status(400).json({
       message: 'Kelas wajib dipilih.',
     });
   }

   const targetClass = findClass(targetClassId);

   if (!targetClass) {
     return res.status(404).json({
       message: 'Kelas akademik tidak ditemukan.',
     });
   }

   // Validasi Guru.
   const targetTeacherId = Number(teacher_id);

   if (
     teacher_id === undefined ||
     !Number.isInteger(targetTeacherId) ||
     targetTeacherId <= 0
   ) {
     return res.status(400).json({
       message: 'Guru pengajar wajib dipilih.',
     });
   }

   const targetTeacher = findTeacher(targetTeacherId);

   if (!targetTeacher) {
     return res.status(404).json({
       message: 'Akun Guru tidak ditemukan.',
     });
   }

    // user_id mencatat Admin yang membuat jadwal.
    // class_id menentukan mahasiswa yang menerima jadwal.
 const result = db.prepare(`
   INSERT INTO schedules (
     user_id,
     class_id,
     teacher_id,
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
   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
 `).run(
   req.user.id,
   targetClassId,
   targetTeacherId,
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
    ac.cohort_year,
    teacher.name AS teacher_name,
    teacher.email AS teacher_email
  FROM schedules s
  LEFT JOIN academic_classes ac
    ON ac.id = s.class_id
  LEFT JOIN users teacher
    ON teacher.id = s.teacher_id
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
      teacher_id,
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

const targetTeacherId = teacher_id === undefined
  ? existing.teacher_id
  : teacher_id === null
    ? null
    : Number(teacher_id);

if (
  targetTeacherId !== null &&
  (
    !Number.isInteger(targetTeacherId) ||
    targetTeacherId <= 0
  )
) {
  return res.status(400).json({
    message: 'teacher_id tidak valid.',
  });
}

if (
  targetTeacherId !== null &&
  !findTeacher(targetTeacherId)
) {
  return res.status(404).json({
    message: 'Akun Guru tidak ditemukan.',
  });
}

    db.prepare(`
      UPDATE schedules
      SET
        class_id = ?,
        teacher_id = ?,
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
      targetTeacherId,
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
      ac.cohort_year,
      teacher.name AS teacher_name,
      teacher.email AS teacher_email
    FROM schedules s
    LEFT JOIN academic_classes ac
      ON ac.id = s.class_id
    LEFT JOIN users teacher
      ON teacher.id = s.teacher_id
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

// Guru mengambil daftar murid dari kelas yang ditugaskan kepadanya.
function getClassStudents(req, res) {
  try {
    const classId = Number(req.params.classId);

    if (!Number.isInteger(classId) || classId <= 0) {
      return res.status(400).json({
        message: 'ID kelas tidak valid.',
      });
    }

    // Pastikan Guru memang ditugaskan mengajar kelas ini.
    const assignedClass = db.prepare(`
      SELECT id
      FROM schedules
      WHERE teacher_id = ?
        AND class_id = ?
      LIMIT 1
    `).get(req.user.id, classId);

    if (!assignedClass) {
      return res.status(403).json({
        message: 'Anda tidak memiliki akses ke kelas ini.',
      });
    }

    // Ambil anggota kelas dengan role Murid.
    const students = db.prepare(`
      SELECT id, name, nim, major
      FROM users
      WHERE class_id = ?
        AND role = 'Murid'
      ORDER BY name ASC
    `).all(classId);

    return res.json({
      message: 'Daftar murid berhasil diambil.',
      total: students.length,
      data: students,
    });
  } catch (error) {
    console.error('Get class students error:', error);

    return res.status(500).json({
      message: 'Gagal mengambil daftar murid.',
    });
  }
}

module.exports = {
  getSchedules,
  getClassStudents,
  createSchedule,
  updateSchedule,
  deleteSchedule,
};