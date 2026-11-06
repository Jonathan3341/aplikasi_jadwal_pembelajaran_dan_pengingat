const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const ACCESS_EXPIRES = process.env.ACCESS_TOKEN_EXPIRES || '15m';

const REFRESH_DAYS = Number(
  process.env.REFRESH_TOKEN_DAYS || 7
);

function createAccessToken(user) {
  return jwt.sign(
    {
      sub: String(user.id),
      email: user.email,
      role: user.role,
    },
    process.env.JWT_ACCESS_SECRET,
    {
      expiresIn: ACCESS_EXPIRES,
    }
  );
}

function createRefreshToken(user) {
  return jwt.sign(
    {
      sub: String(user.id),
      type: 'refresh',
    },
    process.env.JWT_REFRESH_SECRET,
    {
      expiresIn: `${REFRESH_DAYS}d`,
    }
  );
}

function hashToken(token) {
  return crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');
}

function verifyAccessToken(token) {
  return jwt.verify(token, process.env.JWT_ACCESS_SECRET);
}

function verifyRefreshToken(token) {
  return jwt.verify(token, process.env.JWT_REFRESH_SECRET);
}

module.exports = {
  createAccessToken,
  createRefreshToken,
  hashToken,
  verifyAccessToken,
  verifyRefreshToken,
  REFRESH_DAYS,
};