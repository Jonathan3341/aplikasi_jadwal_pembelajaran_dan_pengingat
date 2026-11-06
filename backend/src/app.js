require('dotenv').config();

const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');

const userRoutes = require('./routes/userRoutes');
const scheduleRoutes = require('./routes/scheduleRoutes');
const adminRoutes = require('./routes/adminRoutes');
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
app.use('/api/user', userRoutes);

// Route CRUD Jadwal Pembelajaran.
app.use('/api/schedules', scheduleRoutes);

// Route khusus Admin.
app.use('/api/admin', adminRoutes);

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

const server = app.listen(PORT, () => {
  console.log(`Backend berjalan di http://localhost:${PORT}`);
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