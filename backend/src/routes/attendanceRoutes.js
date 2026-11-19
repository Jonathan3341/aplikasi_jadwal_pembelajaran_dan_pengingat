
const express = require('express');

const {
  getAvailableAttendance,
  submitAttendance,
  getMyAttendance,
  getMyAttendanceSummary,
} = require('../controllers/attendanceController');

const {
  authenticateToken,
  authorizeRoles,
} = require('../middleware/authMiddleware');

const router = express.Router();

// Semua endpoint absensi wajib login dan hanya untuk Murid.
router.use(authenticateToken);
router.use(authorizeRoles('Murid'));

// Melihat jadwal dan status absensi hari ini.
router.get('/available', getAvailableAttendance);

// Mengirim absensi.
router.post('/', submitAttendance);

// Melihat riwayat absensi sendiri.
router.get('/my-history', getMyAttendance);

router.get('/summary', getMyAttendanceSummary);

module.exports = router;
