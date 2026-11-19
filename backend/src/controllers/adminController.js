const bcrypt = require('bcrypt');
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

if (class_id !== undefined) {
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

// Mengambil daftar akun Guru untuk penugasan jadwal.
function getTeachers(req, res) {
  try {
    const teachers = db.prepare(`
      SELECT
        id,
        name,
        email,
        major
      FROM users
      WHERE role = 'Guru'
      ORDER BY
        CASE
          WHEN TRIM(name) = '' THEN email
          ELSE name
        END COLLATE NOCASE ASC
    `).all();

    return res.json({
      message: 'Daftar Guru berhasil diambil.',
      total: teachers.length,
      data: teachers,
    });
  } catch (error) {
    console.error('Get teachers error:', error);

    return res.status(500).json({
      message: 'Gagal mengambil daftar Guru.',
    });
  }
}

async function createTeacher(req, res) {
  try {
    const { name, email, password, major } = req.body;

    // Validasi input.
    if (
      typeof name !== 'string' ||
      typeof email !== 'string' ||
      typeof password !== 'string' ||
      typeof major !== 'string' ||
      !name.trim() ||
      !email.trim() ||
      !password ||
      !major.trim()
    ) {
      return res.status(400).json({
        message: 'Nama, email, password, dan jurusan wajib diisi.',
      });
    }

    const normalizedName = name.trim();
    const normalizedEmail = email.trim().toLowerCase();
    const normalizedMajor = major.trim();

    if (
      normalizedName.length > 100 ||
      normalizedMajor.length > 100
    ) {
      return res.status(400).json({
        message: 'Nama atau jurusan terlalu panjang.',
      });
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
      return res.status(400).json({
        message: 'Format email tidak valid.',
      });
    }

    if (password.length < 8) {
      return res.status(400).json({
        message: 'Password minimal 8 karakter.',
      });
    }

    if (Buffer.byteLength(password, 'utf8') > 72) {
      return res.status(400).json({
        message: 'Password terlalu panjang.',
      });
    }

    // Periksa email yang sudah terdaftar.
    const existingUser = db.prepare(`
      SELECT id FROM users WHERE email = ?
    `).get(normalizedEmail);

    if (existingUser) {
      return res.status(409).json({
        message: 'Email sudah terdaftar.',
      });
    }

    // Hash password sebelum disimpan.
    const passwordHash = await bcrypt.hash(password, 12);

    const result = db.prepare(`
      INSERT INTO users (
        name,
        email,
        password,
        major,
        role
      )
      VALUES (?, ?, ?, ?, 'Guru')
    `).run(
      normalizedName,
      normalizedEmail,
      passwordHash,
      normalizedMajor
    );

    return res.status(201).json({
      message: 'Akun Guru berhasil dibuat.',
      data: {
        id: String(result.lastInsertRowid),
        name: normalizedName,
        email: normalizedEmail,
        major: normalizedMajor,
        role: 'Guru',
      },
    });
  } catch (error) {
    console.error('Create teacher error:', error);

    if (error.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      return res.status(409).json({
        message: 'Email sudah terdaftar.',
      });
    }

    return res.status(500).json({
      message: 'Gagal membuat akun Guru.',
    });
  }
}

// Menghapus akun Guru.
function deleteTeacher(req, res) {
  try {
    const teacherId = Number(req.params.id);

    if (!Number.isInteger(teacherId) || teacherId <= 0) {
      return res.status(400).json({
        message: 'ID Guru tidak valid.',
      });
    }

    // Memastikan akun yang akan dihapus benar-benar Guru.
    const teacher = db.prepare(`
      SELECT id, name, email
      FROM users
      WHERE id = ? AND role = 'Guru'
    `).get(teacherId);

    if (!teacher) {
      return res.status(404).json({
        message: 'Akun Guru tidak ditemukan.',
      });
    }

    // Memeriksa apakah Guru masih memiliki tugas.
    const assignmentUsage = db.prepare(`
      SELECT COUNT(*) AS total
      FROM assignments
      WHERE teacher_id = ?
    `).get(teacherId);

    if (assignmentUsage.total > 0) {
      return res.status(409).json({
        message:
          `Akun Guru tidak dapat dihapus karena masih memiliki ` +
          `${assignmentUsage.total} tugas. ` +
          'Pastikan tugas tersebut sudah ditangani terlebih dahulu.',
        data: {
          assignment_count: assignmentUsage.total,
        },
      });
    }

    // Menghapus akun Guru.
    db.prepare(`
      DELETE FROM users
      WHERE id = ? AND role = 'Guru'
    `).run(teacherId);

    return res.json({
      message: 'Akun Guru berhasil dihapus.',
    });
  } catch (error) {
    console.error('Delete teacher error:', error);

    return res.status(500).json({
      message: 'Gagal menghapus akun Guru.',
    });
  }
}

module.exports = {
  getClasses,
  createClass,
  updateClass,
  deleteClass,
  getStudents,
  getTeachers,
  createTeacher,
  deleteTeacher,
};
