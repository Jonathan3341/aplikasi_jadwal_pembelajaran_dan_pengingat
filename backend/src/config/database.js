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
    class_id INTEGER,
    teacher_id INTEGER,

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

    FOREIGN KEY (class_id)
      REFERENCES academic_classes(id)
      ON DELETE SET NULL,

    FOREIGN KEY (teacher_id)
      REFERENCES users(id)
      ON DELETE SET NULL,

    CHECK(start_time < end_time)
  );
`);

// Periksa ulang kolom setelah tabel dibuat.
let scheduleColumns = db.prepare(
  'PRAGMA table_info(schedules)'
).all();

let scheduleColumnNames = new Set(
  scheduleColumns.map((column) => column.name)
);

// Migrasi class_id untuk database lama.
if (!scheduleColumnNames.has('class_id')) {
  db.exec(`
    ALTER TABLE schedules
    ADD COLUMN class_id INTEGER
    REFERENCES academic_classes(id)
    ON DELETE SET NULL;
  `);
}

// Ambil ulang struktur tabel setelah migrasi class_id.
scheduleColumns = db.prepare(
  'PRAGMA table_info(schedules)'
).all();

scheduleColumnNames = new Set(
  scheduleColumns.map((column) => column.name)
);

// Migrasi teacher_id untuk database lama.
if (!scheduleColumnNames.has('teacher_id')) {
  db.exec(`
    ALTER TABLE schedules
    ADD COLUMN teacher_id INTEGER
    REFERENCES users(id)
    ON DELETE SET NULL;
  `);
}

// Index pencarian jadwal.
db.exec(`
  CREATE INDEX IF NOT EXISTS idx_schedules_class_id
  ON schedules(class_id);

  CREATE INDEX IF NOT EXISTS idx_schedules_teacher_id
  ON schedules(teacher_id);

  CREATE INDEX IF NOT EXISTS idx_schedules_user_id
  ON schedules(user_id);

  CREATE INDEX IF NOT EXISTS idx_schedules_weekday
  ON schedules(weekday);
`);


console.log('SQLite database berhasil diinisialisasi.');

// ==========================================
// TABEL SISTEM TUGAS GURU DAN MURID
// ==========================================

// Tabel tugas yang dibuat oleh Guru.
db.exec(`
  CREATE TABLE IF NOT EXISTS assignments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    teacher_id INTEGER NOT NULL,
    class_id INTEGER NOT NULL,

    title TEXT NOT NULL,
    description TEXT NOT NULL,

    due_at DATETIME,

    status TEXT NOT NULL DEFAULT 'published'
      CHECK(status IN ('published', 'archived')),

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (teacher_id)
      REFERENCES users(id)
      ON DELETE CASCADE,

    FOREIGN KEY (class_id)
      REFERENCES academic_classes(id)
      ON DELETE CASCADE
  );
`);

// Lampiran yang diberikan Guru pada tugas.
db.exec(`
  CREATE TABLE IF NOT EXISTS assignment_attachments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    assignment_id INTEGER NOT NULL,

    attachment_type TEXT NOT NULL
      CHECK(attachment_type IN ('file', 'photo', 'link')),

    original_name TEXT,
    stored_name TEXT,
    file_path TEXT,

    mime_type TEXT,
    file_size INTEGER,

    url TEXT,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (assignment_id)
      REFERENCES assignments(id)
      ON DELETE CASCADE
  );
`);

// Pengumpulan tugas oleh Murid.
db.exec(`
  CREATE TABLE IF NOT EXISTS submissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    assignment_id INTEGER NOT NULL,
    student_id INTEGER NOT NULL,

    submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    status TEXT NOT NULL DEFAULT 'submitted'
      CHECK(status IN ('submitted', 'graded')),

    grade REAL
      CHECK(grade IS NULL OR (grade >= 0 AND grade <= 100)),

    feedback TEXT,

    graded_by INTEGER,
    graded_at DATETIME,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (assignment_id)
      REFERENCES assignments(id)
      ON DELETE CASCADE,

    FOREIGN KEY (student_id)
      REFERENCES users(id)
      ON DELETE CASCADE,

    FOREIGN KEY (graded_by)
      REFERENCES users(id)
      ON DELETE SET NULL,

    UNIQUE (assignment_id, student_id)
  );
`);

// File, foto, atau tautan yang dikumpulkan Murid.
db.exec(`
  CREATE TABLE IF NOT EXISTS submission_attachments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    submission_id INTEGER NOT NULL,

    attachment_type TEXT NOT NULL
      CHECK(attachment_type IN ('file', 'photo', 'link')),

    original_name TEXT,
    stored_name TEXT,
    file_path TEXT,

    mime_type TEXT,
    file_size INTEGER,

    url TEXT,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (submission_id)
      REFERENCES submissions(id)
      ON DELETE CASCADE
  );
`);

// Index untuk mempercepat pengambilan data tugas.
db.exec(`
  CREATE INDEX IF NOT EXISTS idx_assignments_teacher
  ON assignments(teacher_id);

  CREATE INDEX IF NOT EXISTS idx_assignments_class
  ON assignments(class_id);

  CREATE INDEX IF NOT EXISTS idx_assignment_attachments
  ON assignment_attachments(assignment_id);

  CREATE INDEX IF NOT EXISTS idx_submissions_assignment
  ON submissions(assignment_id);

  CREATE INDEX IF NOT EXISTS idx_submissions_student
  ON submissions(student_id);

  CREATE INDEX IF NOT EXISTS idx_submission_attachments
  ON submission_attachments(submission_id);
`);


// ==========================================
// TABEL SISTEM ABSENSI MAHASISWA
// ==========================================

db.exec(`
  CREATE TABLE IF NOT EXISTS attendance_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    schedule_id INTEGER NOT NULL,
    student_id INTEGER NOT NULL,

    attendance_date TEXT NOT NULL,
    check_in_at TEXT NOT NULL,

    latitude REAL NOT NULL,
    longitude REAL NOT NULL,

    accuracy REAL NOT NULL,
    distance REAL NOT NULL,

    status TEXT NOT NULL
      CHECK(status IN ('Hadir', 'Terlambat')),

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (schedule_id)
      REFERENCES schedules(id)
      ON DELETE CASCADE,

    FOREIGN KEY (student_id)
      REFERENCES users(id)
      ON DELETE CASCADE,

    UNIQUE (schedule_id, student_id, attendance_date)
  );
`);

// Index untuk mempercepat pencarian riwayat absensi.
db.exec(`
  CREATE INDEX IF NOT EXISTS idx_attendance_student
  ON attendance_records(student_id);

  CREATE INDEX IF NOT EXISTS idx_attendance_schedule
  ON attendance_records(schedule_id);

  CREATE INDEX IF NOT EXISTS idx_attendance_date
  ON attendance_records(attendance_date);
`);

console.log('Tabel sistem absensi berhasil diperiksa.');
console.log('Tabel sistem tugas berhasil diperiksa.');
console.log('Database location:', databasePath);

module.exports = db;