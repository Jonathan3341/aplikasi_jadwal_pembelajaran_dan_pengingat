
const db = require('./src/config/database');
// Sesuaikan require dengan path database.js
// yang berhasil kamu gunakan sebelumnya.

const readline = require('node:readline/promises');
const { stdin, stdout } = require('node:process');

const rl = readline.createInterface({
  input: stdin,
  output: stdout,
});

async function showUsers() {
  const users = db.prepare(`
    SELECT id, name, email, nim, major, role
    FROM users
    ORDER BY id
  `).all();

  console.log('\n========== DATA USERS ==========');
  console.table(users);
}

async function showSchedules() {
  const schedules = db.prepare(`
    SELECT
      s.id,
      s.user_id,
      u.name AS user_name,
      s.subject,
      s.weekday,
      s.start_time,
      s.end_time,
      s.room
    FROM schedules s
    LEFT JOIN users u ON u.id = s.user_id
    ORDER BY s.id
  `).all();

  console.log('\n========== DATA SCHEDULES ==========');
  console.table(schedules);
}

// ======================================
// HAPUS SATU USER
// ======================================

async function deleteOneUser() {
  await showUsers();

  const id = Number(
    await rl.question('\nMasukkan ID user yang ingin dihapus: ')
  );

  if (!Number.isInteger(id) || id <= 0) {
    console.log('ID tidak valid.');
    return;
  }

  const user = db.prepare(`
    SELECT id, name, email
    FROM users
    WHERE id = ?
  `).get(id);

  if (!user) {
    console.log('User tidak ditemukan.');
    return;
  }

  console.log('\nUser yang akan dihapus:');
  console.table(user);

  console.log(
    'PERINGATAN: Jadwal dan refresh token milik user ini juga akan dihapus.'
  );

  const confirmation = await rl.question(
    '\nKetik HAPUS untuk melanjutkan: '
  );

  if (confirmation !== 'HAPUS') {
    console.log('Penghapusan dibatalkan.');
    return;
  }

  const result = db.prepare(`
    DELETE FROM users WHERE id = ?
  `).run(id);

  console.log(
    result.changes > 0
      ? 'User berhasil dihapus beserta data terkait.'
      : 'Tidak ada data yang dihapus.'
  );
}

// ======================================
// HAPUS SATU JADWAL
// ======================================

async function deleteOneSchedule() {
  await showSchedules();

  const id = Number(
    await rl.question('\nMasukkan ID jadwal yang ingin dihapus: ')
  );

  if (!Number.isInteger(id) || id <= 0) {
    console.log('ID tidak valid.');
    return;
  }

  const schedule = db.prepare(`
    SELECT id, subject, weekday, start_time, end_time
    FROM schedules
    WHERE id = ?
  `).get(id);

  if (!schedule) {
    console.log('Jadwal tidak ditemukan.');
    return;
  }

  console.log('\nJadwal yang akan dihapus:');
  console.table(schedule);

  const confirmation = await rl.question(
    '\nKetik HAPUS untuk melanjutkan: '
  );

  if (confirmation !== 'HAPUS') {
    console.log('Penghapusan dibatalkan.');
    return;
  }

  const result = db.prepare(`
    DELETE FROM schedules WHERE id = ?
  `).run(id);

  console.log(
    result.changes > 0
      ? 'Jadwal berhasil dihapus.'
      : 'Tidak ada data yang dihapus.'
  );
}

// ======================================
// HAPUS SELURUH DATA
// ======================================

async function deleteAllData() {
  const counts = {
    users: db.prepare('SELECT COUNT(*) AS total FROM users').get().total,
    schedules: db.prepare('SELECT COUNT(*) AS total FROM schedules').get().total,
    refreshTokens: db.prepare('SELECT COUNT(*) AS total FROM refresh_tokens').get().total,
  };

  console.log('\n========== DATA YANG AKAN DIHAPUS ==========');
  console.table(counts);

  console.log('\nPERINGATAN!');
  console.log('Semua akun, jadwal, dan refresh token akan dihapus.');
  console.log('Tindakan ini tidak dapat dibatalkan.');

  const confirmation = await rl.question(
    '\nKetik HAPUS SEMUA untuk melanjutkan: '
  );

  if (confirmation !== 'HAPUS SEMUA') {
    console.log('Penghapusan seluruh data dibatalkan.');
    return;
  }

  const clearAll = db.transaction(() => {
    db.prepare('DELETE FROM refresh_tokens').run();
    db.prepare('DELETE FROM schedules').run();
    db.prepare('DELETE FROM users').run();
  });

  clearAll();

  console.log('\nSeluruh data berhasil dihapus!');
  console.log('Struktur tabel database tetap dipertahankan.');
}

// ======================================
// MENU UTAMA
// ======================================

async function main() {
  console.log('\n================================');
  console.log('     SQLITE DATABASE MANAGER');
  console.log('================================');
  console.log('1. Lihat seluruh user');
  console.log('2. Lihat seluruh jadwal');
  console.log('3. Hapus satu user');
  console.log('4. Hapus satu jadwal');
  console.log('5. Hapus seluruh data database');
  console.log('0. Keluar');

  const choice = await rl.question('\nPilih menu: ');

  switch (choice.trim()) {
    case '1':
      await showUsers();
      break;

    case '2':
      await showSchedules();
      break;

    case '3':
      await deleteOneUser();
      break;

    case '4':
      await deleteOneSchedule();
      break;

    case '5':
      await deleteAllData();
      break;

    case '0':
      console.log('Keluar dari Database Manager.');
      return;

    default:
      console.log('Pilihan tidak valid.');
  }
}

main()
  .catch((error) => {
    console.error('Terjadi kesalahan:', error.message);
  })
  .finally(() => {
    rl.close();
    db.close();
  });

console.log('\n=== TABEL ACADEMIC_CLASSES ===');
console.log(
  db.prepare('PRAGMA table_info(academic_classes)').all()
);

console.log('\n=== KOLOM TABEL USERS ===');
console.log(
  db.prepare('PRAGMA table_info(users)').all()
);

console.log('\n=== KOLOM TABEL SCHEDULES ===');
console.log(
  db.prepare('PRAGMA table_info(schedules)').all()
);