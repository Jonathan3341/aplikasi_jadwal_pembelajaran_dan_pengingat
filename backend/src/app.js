require('dotenv').config();

const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');

const authRoutes = require('./routes/authRoutes');
const scheduleRoutes = require('./routes/scheduleRoutes');
const adminRoutes = require('./routes/adminRoutes');
const assignmentRoutes = require('./routes/assignmentRoutes');
const submissionRoutes = require('./routes/submissionRoutes');
const attendanceRoutes = require('./routes/attendanceRoutes');

const {
  cleanupExpiredTokens,
} = require('./controllers/authController');

const app = express();

const PORT = process.env.PORT || 5000;

// Middleware.
app.use(cors({
  origin: process.env.CLIENT_ORIGIN || 'http://localhost:5001',
  credentials: true,
}));

app.use(express.json());
app.use(cookieParser());

// Route pengecekan server.
app.get('/', (req, res) => {
  res.json({
    message: 'Jadwal Pembelajaran API is running.',
  });
});

// Route Authentication.
app.use('/api/user', authRoutes);

// Route CRUD Jadwal Pembelajaran.
app.use('/api/schedules', scheduleRoutes);

// Route khusus Admin.
app.use('/api/admin', adminRoutes);

// Route khusus tugas
app.use('/api/assignments', assignmentRoutes);

//Route khusus pengumpulan tugas
app.use('/api/submissions', submissionRoutes);

// Route untuk Attendance
app.use('/api/attendance', attendanceRoutes);

// Route yang tidak ditemukan.
app.use((req, res) => {
  res.status(404).json({
    message: 'Endpoint tidak ditemukan.',
  });
});


// Penanganan error umum.
app.use((error, req, res, next) => {
  console.error(error);

  res.status(500).json({
    message: 'Terjadi kesalahan pada server.',
  });
});

// Membersihkan refresh token kedaluwarsa.
cleanupExpiredTokens();

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Backend berjalan pada port ${PORT}`);
  console.log(`Akses lokal: http://localhost:${PORT}`);
  console.log(`Akses HP: http://192.168.1.12:${PORT}`);
});

// Menutup koneksi database ketika server dihentikan.
const db = require('./config/database');

function shutdown() {
  server.close(() => {
    db.close();
    process.exit(0);
  });
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);