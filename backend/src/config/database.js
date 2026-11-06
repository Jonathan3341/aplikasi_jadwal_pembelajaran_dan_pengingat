const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

const databaseFolder = path.join(__dirname, '../../database');

if (!fs.existsSync(databaseFolder)) {
  fs.mkdirSync(databaseFolder, { recursive: true });
}

const databasePath = path.join(databaseFolder, 'jadwal.db');

const db = new Database(databasePath);

db.pragma('foreign_keys = ON');
db.pragma('journal_mode = WAL');

// Tabel users
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'Murid'
      CHECK(role IN ('Murid', 'Guru', 'Admin')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
`);

// Migrasi kolom profil pengguna.
const userColumns = db.prepare('PRAGMA table_info(users)').all();

const existingColumns = new Set(
  userColumns.map((column) => column.name)
);

if (!existingColumns.has('name')) {
  db.exec(`
    ALTER TABLE users
    ADD COLUMN name TEXT NOT NULL DEFAULT '';
  `);
}

if (!existingColumns.has('nim')) {
  db.exec(`
    ALTER TABLE users
    ADD COLUMN nim TEXT NOT NULL DEFAULT '';
  `);
}

if (!existingColumns.has('major')) {
  db.exec(`
    ALTER TABLE users
    ADD COLUMN major TEXT NOT NULL DEFAULT '';
  `);
}

// Mencegah NIM yang sama digunakan oleh beberapa akun.
db.exec(`
  CREATE UNIQUE INDEX IF NOT EXISTS idx_users_nim_unique
  ON users(nim)
  WHERE nim IS NOT NULL AND nim <> '';
`);

// Tabel kelas akademik.
db.exec(`
  CREATE TABLE IF NOT EXISTS academic_classes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    class_name TEXT NOT NULL UNIQUE,
    major TEXT NOT NULL,
    cohort_year INTEGER NOT NULL
      CHECK(cohort_year BETWEEN 2000 AND 2100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
`);

// Migrasi class_id pada tabel users.
const userColumnsForClass = db.prepare(
  'PRAGMA table_info(users)'
).all();

const hasUserClassId = userColumnsForClass.some(
  (column) => column.name === 'class_id'
);

if (!hasUserClassId) {
  db.exec(`
    ALTER TABLE users
    ADD COLUMN class_id INTEGER
    REFERENCES academic_classes(id)
    ON DELETE SET NULL;
  `);
}

// Index untuk pencarian mahasiswa berdasarkan kelas.
db.exec(`
  CREATE INDEX IF NOT EXISTS idx_users_class_id
  ON users(class_id);
`);

// Tabel refresh_tokens
db.exec(`
  CREATE TABLE IF NOT EXISTS refresh_tokens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)
      REFERENCES users(id)
      ON DELETE CASCADE
  );
`);

db.exec(`
  CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id
  ON refresh_tokens(user_id);
`);


// Tabel schedules
db.exec(`
  CREATE TABLE IF NOT EXISTS schedules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    user_id INTEGER NOT NULL,

    subject TEXT NOT NULL,
    weekday INTEGER NOT NULL
      CHECK(weekday BETWEEN 1 AND 7),

    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,

    room TEXT DEFAULT '',
    lecturer TEXT DEFAULT '',
    notes TEXT DEFAULT '',

    reminder_enabled INTEGER NOT NULL DEFAULT 0
      CHECK(reminder_enabled IN (0, 1)),

    reminder_minutes INTEGER NOT NULL DEFAULT 15
      CHECK(reminder_minutes >= 0),

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
      REFERENCES users(id)
      ON DELETE CASCADE,

    CHECK(start_time < end_time)
  );
`);

// Migrasi class_id pada tabel schedules.
const scheduleColumns = db.prepare(
  'PRAGMA table_info(schedules)'
).all();

const hasScheduleClassId = scheduleColumns.some(
  (column) => column.name === 'class_id'
);

if (!hasScheduleClassId) {
  db.exec(`
    ALTER TABLE schedules
    ADD COLUMN class_id INTEGER
    REFERENCES academic_classes(id)
    ON DELETE SET NULL;
  `);
}

// Index untuk pencarian jadwal berdasarkan kelas.
db.exec(`
  CREATE INDEX IF NOT EXISTS idx_schedules_class_id
  ON schedules(class_id);
`);

// Index untuk mempercepat pencarian jadwal berdasarkan pengguna
db.exec(`
  CREATE INDEX IF NOT EXISTS idx_schedules_user_id
  ON schedules(user_id);
`);

// Index untuk pencarian jadwal berdasarkan hari
db.exec(`
  CREATE INDEX IF NOT EXISTS idx_schedules_weekday
  ON schedules(weekday);
`);


console.log('SQLite database berhasil diinisialisasi.');
console.log('Database location:', databasePath);

module.exports = db;