const {
  verifyAccessToken,
} = require('../services/tokenService');

function authenticateToken(req, res, next) {
  const authorization = req.headers.authorization;

  if (!authorization || !authorization.startsWith('Bearer ')) {
    return res.status(401).json({
      message: 'Access token tidak ditemukan.',
    });
  }

  const token = authorization.split(' ')[1];

  try {
    const payload = verifyAccessToken(token);

    req.user = {
      id: Number(payload.sub),
      email: payload.email,
      role: payload.role,
    };

    next();
  } catch (error) {
    return res.status(401).json({
      message: 'Access token tidak valid atau kedaluwarsa.',
    });
  }
}

function authorizeRoles(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        message: 'Silakan login terlebih dahulu.',
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        message: 'Kamu tidak memiliki izin untuk mengakses fitur ini.',
      });
    }

    next();
  };
}

module.exports = {
  authenticateToken,
  authorizeRoles,
};