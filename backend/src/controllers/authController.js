const bcrypt = require('bcrypt');
const db = require('../config/database');

const {
  createAccessToken,
  createRefreshToken,
  hashToken,
  verifyRefreshToken,
  REFRESH_DAYS,
} = require('../services/tokenService');

const isProduction = process.env.NODE_ENV === 'production';

const cookieOptions = {
  httpOnly: true,
  secure: isProduction,
  sameSite: 'lax',
  path: '/api/user',
  maxAge: REFRESH_DAYS * 24 * 60 * 60 * 1000,
};

const findUserByEmail = db.prepare(
  'SELECT * FROM users WHERE email = ?'
);

const findUserById = db.prepare(
  'SELECT id, email, role FROM users WHERE id = ?'
);

const findUserByNim = db.prepare(
  'SELECT id FROM users WHERE nim = ?'
);

const findProfileById = db.prepare(`
  SELECT id, name, email, nim, major, role
  FROM users
  WHERE id = ?
`);

const insertUser = db.prepare(`
  INSERT INTO users (name, email, password, nim, major, role)
  VALUES (?, ?, ?, ?, ?, 'Murid')
`);

const insertRefreshToken = db.prepare(`
  INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
  VALUES (?, ?, ?)
`);

const findRefreshToken = db.prepare(`
  SELECT * FROM refresh_tokens
  WHERE token_hash = ? AND expires_at > ?
`);

const deleteRefreshToken = db.prepare(`
  DELETE FROM refresh_tokens
  WHERE token_hash = ?
`);

const deleteExpiredTokens = db.prepare(`
  DELETE FROM refresh_tokens WHERE expires_at <= ?
`);

function setRefreshCookie(res, token) {
  res.cookie('refreshToken', token, cookieOptions);
}

function clearRefreshCookie(res) {
  res.clearCookie('refreshToken', {
    httpOnly: true,
    secure: isProduction,
    sameSite: 'lax',
    path: '/api/user',
  });
}

function saveRefreshToken(user, token) {
  const expiresAt =
    Date.now() + REFRESH_DAYS * 24 * 60 * 60 * 1000;

  insertRefreshToken.run(
    user.id,
    hashToken(token),
    expiresAt
  );
}


// POST /api/user/register
async function register(req, res) {
  try {
    const { name, email, password, nim, major } = req.body;

    // Validasi data wajib.
    if (
      typeof name !== 'string' ||
      typeof email !== 'string' ||
      typeof password !== 'string' ||
      typeof nim !== 'string' ||
      typeof major !== 'string' ||
      !name.trim() ||
      !email.trim() ||
      !password ||
      !nim.trim() ||
      !major.trim()
    ) {
      return res.status(400).json({
        message: 'Nama, email, password, NIM, dan jurusan wajib diisi.',
      });
    }

    const normalizedName = name.trim();
    const normalizedEmail = email.trim().toLowerCase();
    const normalizedNim = nim.trim();
    const normalizedMajor = major.trim();

    if (
      normalizedName.length > 100 ||
      normalizedNim.length > 50 ||
      normalizedMajor.length > 100
    ) {
      return res.status(400).json({
        message: 'Data profil terlalu panjang.',
      });
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
      return res.status(400).json({
        message: 'Format email tidak valid.',
      });
    }

    if (password.length < 8) {
      return res.status(400).json({
        message: 'Password minimal 8 karakter.',
      });
    }

    if (Buffer.byteLength(password, 'utf8') > 72) {
      return res.status(400).json({
        message: 'Password terlalu panjang.',
      });
    }

    if (findUserByEmail.get(normalizedEmail)) {
      return res.status(409).json({
        message: 'Email sudah terdaftar.',
      });
    }

    if (findUserByNim.get(normalizedNim)) {
      return res.status(409).json({
        message: 'NIM sudah terdaftar.',
      });
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const result = insertUser.run(
      normalizedName,
      normalizedEmail,
      passwordHash,
      normalizedNim,
      normalizedMajor
    );

    return res.status(201).json({
      id: String(result.lastInsertRowid),
      name: normalizedName,
      email: normalizedEmail,
      nim: normalizedNim,
      major: normalizedMajor,
      role: 'Murid',
    });
  } catch (error) {
    console.error('Register error:', error);

    if (error.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      return res.status(409).json({
        message: 'Email atau NIM sudah terdaftar.',
      });
    }

    return res.status(500).json({
      message: 'Terjadi kesalahan pada server.',
    });
  }
}


// POST /api/user/login
async function login(req, res) {
  try {
    const { email, password } = req.body;

    if (
      typeof email !== 'string' ||
      typeof password !== 'string' ||
      !email.trim() ||
      !password
    ) {
      return res.status(400).json({
        message: 'Email dan password wajib diisi.',
      });
    }

    const user = findUserByEmail.get(
      email.trim().toLowerCase()
    );

    if (!user) {
      return res.status(401).json({
        message: 'Email atau password salah.',
      });
    }

    const passwordMatch = await bcrypt.compare(
      password,
      user.password
    );

    if (!passwordMatch) {
      return res.status(401).json({
        message: 'Email atau password salah.',
      });
    }

    const accessToken = createAccessToken(user);
    const refreshToken = createRefreshToken(user);

    saveRefreshToken(user, refreshToken);

    setRefreshCookie(res, refreshToken);

    return res.status(200).json({
      id: String(user.id),
      email: user.email,
      accessToken,
    });
  } catch (error) {
    console.error('Login error:', error);

    return res.status(500).json({
      message: 'Terjadi kesalahan pada server.',
    });
  }
}

// POST /api/user/refresh
function refresh(req, res) {
  try {
    const token = req.cookies.refreshToken;

    if (!token) {
      clearRefreshCookie(res);

      return res.status(401).json({
        message: 'Refresh token tidak ditemukan.',
      });
    }

    const payload = verifyRefreshToken(token);

    if (payload.type !== 'refresh') {
      throw new Error('Invalid refresh token type');
    }

    const storedToken = findRefreshToken.get(
      hashToken(token),
      Date.now()
    );

    if (!storedToken) {
      clearRefreshCookie(res);

      return res.status(401).json({
        message: 'Refresh token tidak valid atau kedaluwarsa.',
      });
    }

    const user = findUserById.get(Number(payload.sub));

    if (!user) {
      deleteRefreshToken.run(hashToken(token));
      clearRefreshCookie(res);

      return res.status(401).json({
        message: 'Pengguna tidak ditemukan.',
      });
    }

    // Rotasi refresh token: token lama langsung tidak berlaku.
    const newRefreshToken = createRefreshToken(user);
    const newAccessToken = createAccessToken(user);

    const rotateTokens = db.transaction(() => {
      deleteRefreshToken.run(hashToken(token));
      saveRefreshToken(user, newRefreshToken);
    });

    rotateTokens();

    setRefreshCookie(res, newRefreshToken);

    return res.status(200).json({
      accessToken: newAccessToken,
    });
  } catch (error) {
    clearRefreshCookie(res);

    return res.status(401).json({
      message: 'Sesi tidak valid. Silakan login kembali.',
    });
  }
}

// GET /api/user/profile
function profile(req, res) {
  const user = findProfileById.get(Number(req.user.id));

  if (!user) {
    return res.status(404).json({
      message: 'Pengguna tidak ditemukan.',
    });
  }

  return res.status(200).json({
    id: String(user.id),
    name: user.name,
    email: user.email,
    nim: user.nim,
    major: user.major,
    role: user.role,
  });
}

// POST /api/user/logout
function logout(req, res) {
  const token = req.cookies.refreshToken;

  if (token) {
    deleteRefreshToken.run(hashToken(token));
  }

  clearRefreshCookie(res);

  return res.status(200).json({
    message: 'Logout berhasil.',
  });
}

function cleanupExpiredTokens() {
  deleteExpiredTokens.run(Date.now());
}

module.exports = {
  register,
  login,
  refresh,
  profile,
  logout,
  cleanupExpiredTokens,
};