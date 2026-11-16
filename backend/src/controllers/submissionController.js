
const db = require('../config/database');
const path = require('path');
const fs = require('fs');

// Mengambil lampiran pengumpulan
function getSubmissionAttachments(submissionId) {
  return db.prepare(`
    SELECT
      id,
      attachment_type,
      original_name,
      mime_type,
      file_size,
      url
    FROM submission_attachments
    WHERE submission_id = ?
  `).all(submissionId);
}

// Menghapus file fisik
function deleteStoredFiles(files) {
  for (const file of files) {
    if (file.file_path) {
      const absolutePath = path.resolve(
        __dirname,
        '../../',
        file.file_path
      );

      if (fs.existsSync(absolutePath)) {
        fs.unlinkSync(absolutePath);
      }
    }
  }
}

// Validasi dan membaca tautan
function parseLinks(links) {
  if (!links) return [];

  let parsed;

  try {
    parsed = typeof links === 'string'
      ? JSON.parse(links)
      : links;
  } catch (error) {
    throw new Error('Format tautan tidak valid.');
  }

  if (!Array.isArray(parsed)) {
    throw new Error('Lampiran tautan harus berupa daftar.');
  }

  for (const link of parsed) {
    if (
      !link ||
      typeof link.url !== 'string' ||
      !/^https?:\/\/.+/i.test(link.url.trim())
    ) {
      throw new Error('Tautan pengumpulan tidak valid.');
    }
  }

  return parsed;
}

// Murid mengumpulkan atau memperbarui jawaban tugas
function submitAssignment(req, res, next) {
  const uploadedFiles = req.files || [];
  const oldFiles = [];

  try {
    const assignmentId = Number(req.params.id);
    const studentId = req.user.id;

    if (!Number.isInteger(assignmentId) || assignmentId <= 0) {
      throw new Error('ID tugas tidak valid.');
    }

    const assignment = db.prepare(`
      SELECT id, class_id, status
      FROM assignments
      WHERE id = ?
    `).get(assignmentId);

    if (!assignment || assignment.status !== 'published') {
      return res.status(404).json({
        message: 'Tugas tidak ditemukan atau sudah tidak tersedia.',
      });
    }

    const student = db.prepare(`
      SELECT id, class_id
      FROM users
      WHERE id = ?
    `).get(studentId);

    if (!student || student.class_id !== assignment.class_id) {
      return res.status(403).json({
        message: 'Anda tidak terdaftar di kelas tugas ini.',
      });
    }

    const links = parseLinks(req.body.links);

    const existingSubmission = db.prepare(`
      SELECT id, status
      FROM submissions
      WHERE assignment_id = ? AND student_id = ?
    `).get(assignmentId, studentId);

    if (existingSubmission && existingSubmission.status === 'graded') {
      return res.status(409).json({
        message: 'Tugas sudah dinilai dan tidak dapat diubah.',
      });
    }

    const relativeFiles = uploadedFiles.map((file) => ({
      file,
      filePath: path.relative(
        path.join(__dirname, '../..'),
        file.path
      ).replace(/\\/g, '/'),
    }));

    const transaction = db.transaction(() => {
      let submissionId;

      if (existingSubmission) {
        submissionId = existingSubmission.id;

        const previousAttachments = db.prepare(`
          SELECT file_path
          FROM submission_attachments
          WHERE submission_id = ?
        `).all(submissionId);

        oldFiles.push(...previousAttachments);

        db.prepare(`
          DELETE FROM submission_attachments
          WHERE submission_id = ?
        `).run(submissionId);

        db.prepare(`
          UPDATE submissions
          SET submitted_at = CURRENT_TIMESTAMP,
              updated_at = CURRENT_TIMESTAMP
          WHERE id = ?
        `).run(submissionId);
      } else {
        const result = db.prepare(`
          INSERT INTO submissions (
            assignment_id,
            student_id,
            status
          )
          VALUES (?, ?, 'submitted')
        `).run(assignmentId, studentId);

        submissionId = Number(result.lastInsertRowid);
      }

      const insertAttachment = db.prepare(`
        INSERT INTO submission_attachments (
          submission_id,
          attachment_type,
          original_name,
          stored_name,
          file_path,
          mime_type,
          file_size,
          url
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `);

      for (const item of relativeFiles) {
        const file = item.file;

        const attachmentType = file.mimetype.startsWith('image/')
          ? 'photo'
          : 'file';

        insertAttachment.run(
          submissionId,
          attachmentType,
          file.originalname,
          file.filename,
          item.filePath,
          file.mimetype,
          file.size,
          null
        );
      }

      for (const link of links) {
        const safeUrl = link.url.trim();

        insertAttachment.run(
          submissionId,
          'link',
          link.name?.trim() || safeUrl,
          null,
          null,
          null,
          null,
          safeUrl
        );
      }

      return submissionId;
    });

    const submissionId = transaction();

    // File lama dihapus setelah transaksi database berhasil
    deleteStoredFiles(oldFiles);

    return res.status(existingSubmission ? 200 : 201).json({
      message: 'Pengumpulan tugas berhasil disimpan.',
      data: {
        id: submissionId,
        assignment_id: assignmentId,
      },
    });
  } catch (error) {
    // Bersihkan file baru jika proses penyimpanan gagal
    deleteStoredFiles(
      uploadedFiles.map((file) => ({
        file_path: path.relative(
          path.join(__dirname, '../..'),
          file.path
        ).replace(/\\/g, '/'),
      }))
    );

    if (
      error.message.includes('tidak valid') ||
      error.message.includes('harus berupa daftar')
    ) {
      return res.status(400).json({
        message: error.message,
      });
    }

    next(error);
  }
}

// Guru melihat semua pengumpulan untuk tugas miliknya
function getAssignmentSubmissions(req, res, next) {
  try {
    const assignmentId = Number(req.params.id);

    const assignment = db.prepare(`
      SELECT id, teacher_id
      FROM assignments
      WHERE id = ?
    `).get(assignmentId);

    if (!assignment) {
      return res.status(404).json({
        message: 'Tugas tidak ditemukan.',
      });
    }

    if (assignment.teacher_id !== req.user.id) {
      return res.status(403).json({
        message: 'Anda tidak memiliki akses ke pengumpulan tugas ini.',
      });
    }

    const submissions = db.prepare(`
      SELECT
        s.*,
        u.name AS student_name,
        u.nim AS student_nim
      FROM submissions s
      JOIN users u ON u.id = s.student_id
      WHERE s.assignment_id = ?
      ORDER BY s.submitted_at DESC
    `).all(assignmentId);

    const data = submissions.map((submission) => ({
      ...submission,
      attachments: getSubmissionAttachments(submission.id),
    }));

    return res.json({
      message: 'Daftar pengumpulan berhasil diambil.',
      total: data.length,
      data,
    });
  } catch (error) {
    next(error);
  }
}

// Murid melihat riwayat pengumpulan miliknya
function getMySubmissions(req, res, next) {
  try {
    const submissions = db.prepare(`
      SELECT
        s.*,
        a.title AS assignment_title,
        a.due_at,
        a.class_id
      FROM submissions s
      JOIN assignments a ON a.id = s.assignment_id
      WHERE s.student_id = ?
      ORDER BY s.submitted_at DESC
    `).all(req.user.id);

    const data = submissions.map((submission) => ({
      ...submission,
      attachments: getSubmissionAttachments(submission.id),
    }));

    return res.json({
      message: 'Riwayat pengumpulan berhasil diambil.',
      total: data.length,
      data,
    });
  } catch (error) {
    next(error);
  }
}

// Guru memberikan nilai dan catatan evaluasi
function gradeSubmission(req, res, next) {
  try {
    const submissionId = Number(req.params.id);
    const { grade, feedback } = req.body;

    if (!Number.isInteger(submissionId) || submissionId <= 0) {
      return res.status(400).json({
        message: 'ID pengumpulan tidak valid.',
      });
    }

    const numericGrade = Number(grade);

    if (
      grade === undefined ||
      grade === null ||
      grade === '' ||
      !Number.isFinite(numericGrade) ||
      numericGrade < 0 ||
      numericGrade > 100
    ) {
      return res.status(400).json({
        message: 'Nilai harus berupa angka antara 0 sampai 100.',
      });
    }

    const submission = db.prepare(`
      SELECT
        s.id,
        a.teacher_id
      FROM submissions s
      JOIN assignments a ON a.id = s.assignment_id
      WHERE s.id = ?
    `).get(submissionId);

    if (!submission) {
      return res.status(404).json({
        message: 'Pengumpulan tugas tidak ditemukan.',
      });
    }

    if (submission.teacher_id !== req.user.id) {
      return res.status(403).json({
        message: 'Anda tidak memiliki akses untuk menilai tugas ini.',
      });
    }

    db.prepare(`
      UPDATE submissions
      SET grade = ?,
          feedback = ?,
          status = 'graded',
          graded_by = ?,
          graded_at = CURRENT_TIMESTAMP,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `).run(
      numericGrade,
      feedback || '',
      req.user.id,
      submissionId
    );

    return res.json({
      message: 'Penilaian tugas berhasil disimpan.',
      data: {
        id: submissionId,
        grade: numericGrade,
        feedback: feedback || '',
        status: 'graded',
      },
    });
  } catch (error) {
    next(error);
  }
}


function downloadSubmissionAttachment(req, res, next) {
  try {
    const attachmentId = Number(req.params.id);

    if (!Number.isInteger(attachmentId) || attachmentId <= 0) {
      return res.status(400).json({
        message: 'ID lampiran tidak valid.',
      });
    }

    const attachment = db.prepare(`
      SELECT
        sa.id,
        sa.original_name,
        sa.file_path,
        sa.attachment_type,
        s.student_id,
        a.teacher_id
      FROM submission_attachments sa
      JOIN submissions s ON s.id = sa.submission_id
      JOIN assignments a ON a.id = s.assignment_id
      WHERE sa.id = ?
    `).get(attachmentId);

    if (!attachment) {
      return res.status(404).json({
        message: 'Lampiran pengumpulan tidak ditemukan.',
      });
    }

    if (attachment.attachment_type === 'link') {
      return res.status(400).json({
        message: 'Lampiran ini berupa tautan, bukan file.',
      });
    }

    const isOwner =
      req.user.role === 'Murid' &&
      attachment.student_id === req.user.id;

    const isAssignedTeacher =
      req.user.role === 'Guru' &&
      attachment.teacher_id === req.user.id;

    if (!isOwner && !isAssignedTeacher) {
      return res.status(403).json({
        message: 'Anda tidak memiliki akses ke file ini.',
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
  submitAssignment,
  getAssignmentSubmissions,
  getMySubmissions,
  gradeSubmission,
  downloadSubmissionAttachment,
};
