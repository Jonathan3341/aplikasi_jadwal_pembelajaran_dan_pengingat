const db = require('../config/database');
const path = require('path');
const fs = require('fs');

// Memeriksa apakah Guru memang mengajar di kelas tersebut
function isTeacherAssignedToClass(teacherId, classId) {
  const result = db.prepare(`
    SELECT id
    FROM schedules
    WHERE teacher_id = ? AND class_id = ?
    LIMIT 1
  `).get(teacherId, classId);

  return Boolean(result);
}

// Memeriksa hak akses terhadap tugas
function canAccessAssignment(assignment, user) {
  if (user.role === 'Guru') {
    return assignment.teacher_id === user.id;
  }

  if (user.role === 'Murid') {
    const student = db.prepare(`
      SELECT class_id
      FROM users
      WHERE id = ?
    `).get(user.id);

    return Boolean(
      student &&
      student.class_id &&
      student.class_id === assignment.class_id
    );
  }

  return false;
}

// Mengambil lampiran tugas
function getAttachments(assignmentId) {
  return db.prepare(`
    SELECT
      id,
      attachment_type,
      original_name,
      mime_type,
      file_size,
      url
    FROM assignment_attachments
    WHERE assignment_id = ?
  `).all(assignmentId);
}

// Membuat tugas baru oleh Guru
function createAssignment(req, res, next) {
  const uploadedFiles = req.files || [];

  try {
const {
  class_id,
  title,
  description,
  due_at,
  links,
} = req.body;

    if (!class_id || !title || !title.trim()) {
      return res.status(400).json({
        message: 'Kelas dan judul tugas wajib diisi.',
      });
    }

    const classId = Number(class_id);

    if (!Number.isInteger(classId) || classId <= 0) {
      return res.status(400).json({
        message: 'ID kelas tidak valid.',
      });
    }

    if (!isTeacherAssignedToClass(req.user.id, classId)) {
      return res.status(403).json({
        message: 'Anda tidak memiliki akses mengajar di kelas tersebut.',
      });
    }

    const createTransaction = db.transaction(() => {
      const result = db.prepare(`
        INSERT INTO assignments (
          teacher_id,
          class_id,
          title,
          description,
          due_at,
          status
        )
        VALUES (?, ?, ?, ?, ?, 'published')
      `).run(
        req.user.id,
        classId,
        title.trim(),
        description || '',
        due_at || null
      );

      const assignmentId = Number(result.lastInsertRowid);

      const insertAttachment = db.prepare(`
        INSERT INTO assignment_attachments (
          assignment_id,
          attachment_type,
          original_name,
          stored_name,
          file_path,
          mime_type,
          file_size,
          url
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, NULL)
      `);

      for (const file of uploadedFiles) {
        const attachmentType = file.mimetype.startsWith('image/')
          ? 'photo'
          : 'file';

        const relativePath = path
          .relative(path.join(__dirname, '../..'), file.path)
          .replace(/\\/g, '/');

        insertAttachment.run(
          assignmentId,
          attachmentType,
          file.originalname,
          file.filename,
          relativePath,
          file.mimetype,
          file.size
        );
      }

      // Menyimpan lampiran berupa tautan
      let parsedLinks = [];

      if (links) {
        try {
          parsedLinks = typeof links === 'string'
            ? JSON.parse(links)
            : links;
        } catch (error) {
          throw new Error('Format lampiran tautan tidak valid.');
        }
      }

      if (!Array.isArray(parsedLinks)) {
        throw new Error('Lampiran tautan harus berupa daftar.');
      }

      const insertLink = db.prepare(`
        INSERT INTO assignment_attachments (
          assignment_id,
          attachment_type,
          original_name,
          stored_name,
          file_path,
          mime_type,
          file_size,
          url
        )
        VALUES (?, 'link', ?, NULL, NULL, NULL, NULL, ?)
      `);

      for (const link of parsedLinks) {
        if (
          !link ||
          typeof link.url !== 'string' ||
          !/^https?:\/\/.+/i.test(link.url.trim())
        ) {
          throw new Error('Tautan lampiran tidak valid.');
        }

        const safeUrl = link.url.trim();

        insertLink.run(
          assignmentId,
          link.name?.trim() || safeUrl,
          safeUrl
        );
      }

      return assignmentId;
    });

    const assignmentId = createTransaction();

    return res.status(201).json({
      message: 'Tugas berhasil dibuat.',
      data: {
        id: assignmentId,
      },
    });
  } catch (error) {
    // Hapus file yang telanjur diunggah jika proses database gagal
    for (const file of uploadedFiles) {
      if (fs.existsSync(file.path)) {
        fs.unlinkSync(file.path);
      }
    }

    next(error);
  }
}

// Mengambil daftar tugas sesuai peran pengguna
function getAssignments(req, res, next) {
  try {
    let assignments;

    if (req.user.role === 'Guru') {
      assignments = db.prepare(`
        SELECT
          a.*,
          c.class_name,
          c.major,
          c.cohort_year
        FROM assignments a
        JOIN academic_classes c ON c.id = a.class_id
        WHERE a.teacher_id = ?
        ORDER BY a.created_at DESC
      `).all(req.user.id);
    } else if (req.user.role === 'Murid') {
      const student = db.prepare(`
        SELECT class_id
        FROM users
        WHERE id = ?
      `).get(req.user.id);

      if (!student || !student.class_id) {
        return res.json({
          message: 'Daftar tugas berhasil diambil.',
          total: 0,
          data: [],
        });
      }

      assignments = db.prepare(`
        SELECT
          a.*,
          c.class_name,
          c.major,
          c.cohort_year
        FROM assignments a
        JOIN academic_classes c ON c.id = a.class_id
        WHERE a.class_id = ?
          AND a.status = 'published'
        ORDER BY a.created_at DESC
      `).all(student.class_id);
    } else {
      return res.status(403).json({
        message: 'Anda tidak memiliki akses.',
      });
    }

    const data = assignments.map((assignment) => ({
      ...assignment,
      attachments: getAttachments(assignment.id),
    }));

    return res.json({
      message: 'Daftar tugas berhasil diambil.',
      total: data.length,
      data,
    });
  } catch (error) {
    next(error);
  }
}

// Mengambil detail satu tugas
function getAssignmentById(req, res, next) {
  try {
    const assignmentId = Number(req.params.id);

    if (!Number.isInteger(assignmentId) || assignmentId <= 0) {
      return res.status(400).json({
        message: 'ID tugas tidak valid.',
      });
    }

    const assignment = db.prepare(`
      SELECT
        a.*,
        c.class_name,
        c.major,
        c.cohort_year
      FROM assignments a
      JOIN academic_classes c ON c.id = a.class_id
      WHERE a.id = ?
    `).get(assignmentId);

    if (!assignment) {
      return res.status(404).json({
        message: 'Tugas tidak ditemukan.',
      });
    }

    if (!canAccessAssignment(assignment, req.user)) {
      return res.status(403).json({
        message: 'Anda tidak memiliki akses ke tugas ini.',
      });
    }

    return res.json({
      message: 'Detail tugas berhasil diambil.',
      data: {
        ...assignment,
        attachments: getAttachments(assignment.id),
      },
    });
  } catch (error) {
    next(error);
  }
}


function downloadAssignmentAttachment(req, res, next) {
  try {
    const attachmentId = Number(req.params.id);

    if (!Number.isInteger(attachmentId) || attachmentId <= 0) {
      return res.status(400).json({
        message: 'ID lampiran tidak valid.',
      });
    }

    const attachment = db.prepare(`
      SELECT
        aa.id,
        aa.original_name,
        aa.file_path,
        aa.attachment_type,
        a.id AS assignment_id,
        a.teacher_id,
        a.class_id,
        a.status
      FROM assignment_attachments aa
      JOIN assignments a ON a.id = aa.assignment_id
      WHERE aa.id = ?
    `).get(attachmentId);

    if (!attachment) {
      return res.status(404).json({
        message: 'Lampiran tidak ditemukan.',
      });
    }

    if (attachment.attachment_type === 'link') {
      return res.status(400).json({
        message: 'Lampiran ini berupa tautan, bukan file.',
      });
    }

    const allowed = canAccessAssignment(attachment, req.user);

    if (!allowed || (
      req.user.role === 'Murid' &&
      attachment.status !== 'published'
    )) {
      return res.status(403).json({
        message: 'Anda tidak memiliki akses ke lampiran ini.',
      });
    }

    const backendDirectory = path.resolve(__dirname, '../..');
    const absolutePath = path.resolve(
      backendDirectory,
      attachment.file_path
    );

    if (!absolutePath.startsWith(backendDirectory + path.sep)) {
      return res.status(400).json({
        message: 'Lokasi file tidak valid.',
      });
    }

    if (!fs.existsSync(absolutePath)) {
      return res.status(404).json({
        message: 'File tidak ditemukan di server.',
      });
    }

    return res.download(absolutePath, attachment.original_name);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createAssignment,
  getAssignments,
  getAssignmentById,
  downloadAssignmentAttachment,
};