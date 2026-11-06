
const express = require('express');

const {
  getClasses,
  createClass,
  updateClass,
  deleteClass,
  getStudents,
  assignStudentToClass,
} = require('../controllers/adminController');

const {
  authenticateToken,
  authorizeRoles,
} = require('../middleware/authMiddleware');

const router = express.Router();

// Semua endpoint Admin wajib login dan memiliki role Admin.
router.use(
  authenticateToken,
  authorizeRoles('Admin')
);

// Pengelolaan kelas akademik.
router.get('/classes', getClasses);
router.post('/classes', createClass);
router.put('/classes/:id', updateClass);
router.delete('/classes/:id', deleteClass);

// Pengelolaan mahasiswa.
router.get('/students', getStudents);
router.put('/students/class', assignStudentToClass);

module.exports = router;
