
const express = require('express');

const {
  getSchedules,
  getClassStudents,
  createSchedule,
  updateSchedule,
  deleteSchedule,
} = require('../controllers/scheduleController');

const {
  authenticateToken,
  authorizeRoles,
} = require('../middleware/authMiddleware');

const router = express.Router();

// Semua endpoint jadwal wajib login.
router.use(authenticateToken);

// Semua role yang login boleh melihat jadwal.
router.get('/', getSchedules);

// Hanya Guru yang dapat melihat anggota kelas yang ditugaskan.
router.get(
  '/classes/:classId/students',
  authorizeRoles('Guru'),
  getClassStudents
);

// Hanya Admin yang boleh mengelola jadwal.
router.post('/', authorizeRoles('Admin'), createSchedule);
router.put('/:id', authorizeRoles('Admin'), updateSchedule);
router.delete('/:id', authorizeRoles('Admin'), deleteSchedule);

module.exports = router;
