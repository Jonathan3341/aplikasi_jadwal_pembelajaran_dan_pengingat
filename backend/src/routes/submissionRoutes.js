
const express = require('express');
const router = express.Router();

const {
  authenticateToken,
  authorizeRoles,
} = require('../middleware/authMiddleware');

const {
  submissionUpload,
} = require('../middleware/uploadMiddleware');

const {
  submitAssignment,
  getAssignmentSubmissions,
  getMySubmissions,
  gradeSubmission,
  downloadSubmissionAttachment,
} = require('../controllers/submissionController');

router.use(authenticateToken);

// Murid mengumpulkan tugas beserta file/foto
router.post(
  '/:id',
  authorizeRoles('Murid'),
  submissionUpload.array('attachments', 5),
  submitAssignment
);

// Murid melihat riwayat pengumpulan miliknya
router.get(
  '/my-submissions',
  authorizeRoles('Murid'),
  getMySubmissions
);

// Guru melihat pengumpulan untuk tugas miliknya
router.get(
  '/assignment/:id',
  authorizeRoles('Guru'),
  getAssignmentSubmissions
);

// Guru memberikan nilai dan feedback
router.put(
  '/:id/grade',
  authorizeRoles('Guru'),
  gradeSubmission
);

router.get(
  '/attachments/:id/download',
  authorizeRoles('Guru', 'Murid'),
  downloadSubmissionAttachment
);

module.exports = router;
