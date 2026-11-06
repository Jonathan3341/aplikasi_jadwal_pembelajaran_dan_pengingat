require('dotenv').config();
const bcrypt = require('bcrypt');
const db = require('./database');

async function createAdmin() {
  try {
    const name = process.env.ADMIN_NAME;
    const email = process.env.ADMIN_EMAIL;
    const password = process.env.ADMIN_PASSWORD;

    if (!name || !email || !password) {
      throw new Error(
        'ADMIN_NAME, ADMIN_EMAIL, dan ADMIN_PASSWORD wajib diisi.'
      );
    }

    if (password.length < 8 || Buffer.byteLength(password, 'utf8') > 72) {
      throw new Error('Password harus 8–72 byte.');
    }

    const normalizedEmail = email.trim().toLowerCase();

    const existing = db.prepare(`
      SELECT id, role
      FROM users
      WHERE email = ?
    `).get(normalizedEmail);

    if (existing) {
      console.log('Email sudah terdaftar.');
      console.log('ID:', existing.id);
      console.log('Role saat ini:', existing.role);
      console.log('Tidak ada perubahan pada akun tersebut.');
      return;
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const result = db.prepare(`
      INSERT INTO users (
        name,
        email,
        password,
        nim,
        major,
        role
      )
      VALUES (?, ?, ?, '', '', 'Admin')
    `).run(
      name.trim(),
      normalizedEmail,
      passwordHash
    );

    console.log('Akun Admin berhasil dibuat.');
    console.log('ID:', result.lastInsertRowid);
    console.log('Nama:', name);
    console.log('Email:', normalizedEmail);
    console.log('Role: Admin');
  } finally {
    db.close();
  }
}

createAdmin().catch((error) => {
  console.error('Gagal membuat akun Admin:', error.message);
  process.exitCode = 1;
});
