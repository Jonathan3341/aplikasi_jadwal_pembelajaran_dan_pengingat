const express = require('express');

const {
  getRegistrationClasses,
  register,
  login,
  refresh,
  profile,
  logout,
} = require('../controllers/authController');

const {
  authenticateToken,
  authorizeRoles,
} = require('../middleware/authMiddleware');

const router = express.Router();

// Mengambil daftar kelas untuk registrasi Murid.
// Endpoint ini tidak membutuhkan login.
router.get('/registration-classes', getRegistrationClasses);

router.post('/register', register);
router.post('/login', login);
router.post('/refresh', refresh);

router.get(
  '/profile',
  authenticateToken,
  profile
);

router.post(
  '/logout',
  authenticateToken,
  logout
);

// Endpoint khusus role Admin.
router.get(
  '/admin',
  authenticateToken,
  authorizeRoles('Admin'),
  (req, res) => {
    res.json({
      message: 'Selamat datang Admin.',
    });
  }
);

// Endpoint khusus Guru dan Admin.
router.get(
  '/teacher',
  authenticateToken,
  authorizeRoles('Guru', 'Admin'),
  (req, res) => {
    res.json({
      message: 'Akses Guru berhasil.',
    });
  }
);

module.exports = router;
