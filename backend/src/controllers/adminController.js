
const db = require('../config/database');

// Mengambil daftar kelas akademik.
function getClasses(req, res) {
  try {
    const classes = db.prepare(`
      SELECT
        ac.*,
        COUNT(DISTINCT u.id) AS student_count,
        COUNT(DISTINCT s.id) AS schedule_count
      FROM academic_classes ac
      LEFT JOIN users u
        ON u.class_id = ac.id AND u.role = 'Murid'
      LEFT JOIN schedules s
        ON s.class_id = ac.id
      GROUP BY ac.id
      ORDER BY ac.cohort_year DESC, ac.class_name ASC
    `).all();

    return res.json({
      message: 'Daftar kelas berhasil diambil.',
      total: classes.length,
      data: classes,
    });
  } catch (error) {
    console.error('Get classes error:', error);

    return res.status(500).json({
      message: 'Gagal mengambil daftar kelas.',
    });
  }
}

// Membuat kelas akademik.
function createClass(req, res) {
  try {
    const { class_name, major, cohort_year } = req.body;

    if (
      typeof class_name !== 'string' ||
      typeof major !== 'string' ||
      !class_name.trim() ||
      !major.trim()
    ) {
      return res.status(400).json({
        message: 'Nama kelas dan jurusan wajib diisi.',
      });
    }

    const normalizedName = class_name.trim();
    const normalizedMajor = major.trim();
    const year = Number(cohort_year);

    if (
      normalizedName.length > 50 ||
      normalizedMajor.length > 100
    ) {
      return res.status(400).json({
        message: 'Nama kelas atau jurusan terlalu panjang.',
      });
    }

    if (!Number.isInteger(year) || year < 2000 || year > 2100) {
      return res.status(400).json({
        message: 'Tahun angkatan tidak valid.',
      });
    }

    const result = db.prepare(`
      INSERT INTO academic_classes (
        class_name,
        major,
        cohort_year
      )
      VALUES (?, ?, ?)
    `).run(normalizedName, normalizedMajor, year);

    const newClass = db.prepare(`
      SELECT *
      FROM academic_classes
      WHERE id = ?
    `).get(result.lastInsertRowid);

    return res.status(201).json({
      message: 'Kelas akademik berhasil dibuat.',
      data: newClass,
    });
  } catch (error) {
    console.error('Create class error:', error);

    if (error.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      return res.status(409).json({
        message: 'Nama kelas tersebut sudah digunakan.',
      });
    }

    return res.status(500).json({
      message: 'Gagal membuat kelas akademik.',
    });
  }
}

// Mengubah data kelas.
function updateClass(req, res) {
  try {
    const classId = Number(req.params.id);

    if (!Number.isInteger(classId) || classId <= 0) {
      return res.status(400).json({
        message: 'ID kelas tidak valid.',
      });
    }

    const existing = db.prepare(`
      SELECT *
      FROM academic_classes
      WHERE id = ?
    `).get(classId);

    if (!existing) {
      return res.status(404).json({
        message: 'Kelas tidak ditemukan.',
      });
    }

    const { class_name, major, cohort_year } = req.body;

    if (
      typeof class_name !== 'string' ||
      typeof major !== 'string' ||
      !class_name.trim() ||
      !major.trim()
    ) {
      return res.status(400).json({
        message: 'Nama kelas dan jurusan wajib diisi.',
      });
    }

    const normalizedName = class_name.trim();
    const normalizedMajor = major.trim();
    const year = Number(cohort_year);

    if (
      normalizedName.length > 50 ||
      normalizedMajor.length > 100
    ) {
      return res.status(400).json({
        message: 'Nama kelas atau jurusan terlalu panjang.',
      });
    }

    if (!Number.isInteger(year) || year < 2000 || year > 2100) {
      return res.status(400).json({
        message: 'Tahun angkatan tidak valid.',
      });
    }

    db.prepare(`
      UPDATE academic_classes
      SET
        class_name = ?,
        major = ?,
        cohort_year = ?
      WHERE id = ?
    `).run(
      normalizedName,
      normalizedMajor,
      year,
      classId
    );

    const updatedClass = db.prepare(`
      SELECT *
      FROM academic_classes
      WHERE id = ?
    `).get(classId);

    return res.json({
      message: 'Kelas berhasil diperbarui.',
      data: updatedClass,
    });
  } catch (error) {
    console.error('Update class error:', error);

    if (error.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      return res.status(409).json({
        message: 'Nama kelas tersebut sudah digunakan.',
      });
    }

    return res.status(500).json({
      message: 'Gagal memperbarui kelas.',
    });
  }
}

// Menghapus kelas yang belum memiliki mahasiswa atau jadwal.
function deleteClass(req, res) {
  try {
    const classId = Number(req.params.id);

    if (!Number.isInteger(classId) || classId <= 0) {
      return res.status(400).json({
        message: 'ID kelas tidak valid.',
      });
    }

    const existing = db.prepare(`
      SELECT id
      FROM academic_classes
      WHERE id = ?
    `).get(classId);

    if (!existing) {
      return res.status(404).json({
        message: 'Kelas tidak ditemukan.',
      });
    }

    const usage = db.prepare(`
      SELECT
        (
          SELECT COUNT(*)
          FROM users
          WHERE class_id = ? AND role = 'Murid'
        ) AS student_count,
        (
          SELECT COUNT(*)
          FROM schedules
          WHERE class_id = ?
        ) AS schedule_count
    `).get(classId, classId);

    if (usage.student_count > 0 || usage.schedule_count > 0) {
      return res.status(409).json({
        message:
          'Kelas masih memiliki mahasiswa atau jadwal. ' +
          'Pindahkan mahasiswa dan jadwal terlebih dahulu.',
        data: usage,
      });
    }

    db.prepare(`
      DELETE FROM academic_classes
      WHERE id = ?
    `).run(classId);

    return res.json({
      message: 'Kelas berhasil dihapus.',
    });
  } catch (error) {
    console.error('Delete class error:', error);

    return res.status(500).json({
      message: 'Gagal menghapus kelas.',
    });
  }
}

// Mengambil daftar mahasiswa.
function getStudents(req, res) {
  try {
    const { class_id, search } = req.query;

    let sql = `
      SELECT
        u.id,
        u.name,
        u.email,
        u.nim,
        u.major,
        u.class_id,
        ac.class_name,
        ac.cohort_year
      FROM users u
      LEFT JOIN academic_classes ac
        ON ac.id = u.class_id
      WHERE u.role = 'Murid'
    `;

    const params = [];

    if (class_id === 'unassigned') {
      sql += ' AND u.class_id IS NULL';
    } else if (class_id !== undefined) {
      const classId = Number(class_id);

      if (!Number.isInteger(classId) || classId <= 0) {
        return res.status(400).json({
          message: 'Filter ID kelas tidak valid.',
        });
      }

      sql += ' AND u.class_id = ?';
      params.push(classId);
    }

    if (typeof search === 'string' && search.trim()) {
      sql += `
        AND (
          u.name LIKE ?
          OR u.nim LIKE ?
          OR u.email LIKE ?
        )
      `;

      const keyword = `%${search.trim()}%`;

      params.push(keyword, keyword, keyword);
    }

    sql += ' ORDER BY u.name ASC';

    const students = db.prepare(sql).all(...params);

    return res.json({
      message: 'Daftar mahasiswa berhasil diambil.',
      total: students.length,
      data: students,
    });
  } catch (error) {
    console.error('Get students error:', error);

    return res.status(500).json({
      message: 'Gagal mengambil daftar mahasiswa.',
    });
  }
}

// Menempatkan mahasiswa ke kelas berdasarkan NIM.
// class_id boleh null untuk mengeluarkan mahasiswa dari kelas.
function assignStudentToClass(req, res) {
  try {
    const { nim, class_id } = req.body;

    if (
      typeof nim !== 'string' ||
      !nim.trim() ||
      !Object.prototype.hasOwnProperty.call(req.body, 'class_id')
    ) {
      return res.status(400).json({
        message: 'NIM dan class_id wajib diberikan.',
      });
    }

    const student = db.prepare(`
      SELECT id, name, nim, major, role
      FROM users
      WHERE nim = ?
    `).get(nim.trim());

    if (!student || student.role !== 'Murid') {
      return res.status(404).json({
        message: 'Mahasiswa dengan NIM tersebut tidak ditemukan.',
      });
    }

    let targetClassId = null;

    if (class_id !== null) {
      targetClassId = Number(class_id);

      if (!Number.isInteger(targetClassId) || targetClassId <= 0) {
        return res.status(400).json({
          message: 'class_id tidak valid.',
        });
      }

      const targetClass = db.prepare(`
        SELECT id, class_name, major
        FROM academic_classes
        WHERE id = ?
      `).get(targetClassId);

      if (!targetClass) {
        return res.status(404).json({
          message: 'Kelas akademik tidak ditemukan.',
        });
      }

      if (
        student.major.trim().toLowerCase() !==
        targetClass.major.trim().toLowerCase()
      ) {
        return res.status(400).json({
          message:
            'Jurusan mahasiswa tidak sesuai dengan jurusan kelas.',
        });
      }
    }

    db.prepare(`
      UPDATE users
      SET class_id = ?
      WHERE id = ? AND role = 'Murid'
    `).run(targetClassId, student.id);

    const updatedStudent = db.prepare(`
      SELECT
        u.id,
        u.name,
        u.email,
        u.nim,
        u.major,
        u.class_id,
        ac.class_name
      FROM users u
      LEFT JOIN academic_classes ac
        ON ac.id = u.class_id
      WHERE u.id = ?
    `).get(student.id);

    return res.json({
      message: targetClassId === null
        ? 'Mahasiswa berhasil dikeluarkan dari kelas.'
        : 'Mahasiswa berhasil dimasukkan ke kelas.',
      data: updatedStudent,
    });
  } catch (error) {
    console.error('Assign student error:', error);

    return res.status(500).json({
      message: 'Gagal mengatur kelas mahasiswa.',
    });
  }
}

module.exports = {
  getClasses,
  createClass,
  updateClass,
  deleteClass,
  getStudents,
  assignStudentToClass,
};
