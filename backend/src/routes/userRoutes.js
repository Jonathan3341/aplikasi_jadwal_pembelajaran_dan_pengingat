const express = require('express');

const {
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

// Contoh endpoint khusus role.
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