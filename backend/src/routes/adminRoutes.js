
const express = require('express');

const {
  getClasses,
  createClass,
  updateClass,
  deleteClass,
  getStudents,
  getTeachers,
  createTeacher,
  deleteTeacher,
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

// Pengelolaan Guru.
router.get('/teachers', getTeachers);
router.post('/teachers', createTeacher);
router.delete('/teachers/:id', deleteTeacher);

module.exports = router;
