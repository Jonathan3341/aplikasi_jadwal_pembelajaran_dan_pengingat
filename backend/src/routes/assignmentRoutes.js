
const express = require('express');
const router = express.Router();

const {
  createAssignment,
  getAssignments,
  getAssignmentById,
  downloadAssignmentAttachment,
  updateAssignment,
} = require('../controllers/assignmentController');

const {
  authenticateToken,
  authorizeRoles,
} = require('../middleware/authMiddleware');

const {
  assignmentUpload,
} = require('../middleware/uploadMiddleware');

// Semua endpoint wajib menggunakan token
router.use(authenticateToken);

// Guru membuat tugas beserta maksimal 5 lampiran
router.post(
  '/',
  authorizeRoles('Guru'),
  assignmentUpload.array('attachments', 5),
  createAssignment
);

// Guru dan Murid mengambil daftar tugas
router.get(
  '/',
  authorizeRoles('Guru', 'Murid'),
  getAssignments
);

// Guru dan Murid mengambil detail tugas
router.get(
  '/:id',
  authorizeRoles('Guru', 'Murid'),
  getAssignmentById
);

// Permintaan download harus melewati autentifikasi dan otorisasi
router.get(
  '/attachments/:id/download',
  authorizeRoles('Guru', 'Murid'),
  downloadAssignmentAttachment
);

// Guru mengedit tugas miliknya sendiri.
router.put(
  '/:id',
  authorizeRoles('Guru'),
  updateAssignment
);

module.exports = router;
