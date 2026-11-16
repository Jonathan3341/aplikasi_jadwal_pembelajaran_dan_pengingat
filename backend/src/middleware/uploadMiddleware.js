
const multer = require('multer');
const path = require('path');
const crypto = require('crypto');

// Lokasi folder penyimpanan
const assignmentDirectory = path.join(
  __dirname,
  '../../uploads/assignments'
);

const submissionDirectory = path.join(
  __dirname,
  '../../uploads/submissions'
);

// Jenis file yang diperbolehkan
const allowedMimeTypes = [
  // Dokumen
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.ms-powerpoint',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'text/plain',

  // Gambar
  'image/jpeg',
  'image/png',
  'image/webp',
];

// Membuat konfigurasi penyimpanan
function createStorage(destination) {
  return multer.diskStorage({
    destination: (req, file, cb) => {
      cb(null, destination);
    },

    filename: (req, file, cb) => {
      const extension = path.extname(file.originalname).toLowerCase();
      const uniqueName = `${crypto.randomUUID()}${extension}`;

      cb(null, uniqueName);
    },
  });
}

// Validasi tipe file
function fileFilter(req, file, cb) {
  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Jenis file tidak diperbolehkan.'));
  }
}

// Batas unggahan
const uploadLimits = {
  fileSize: 10 * 1024 * 1024, // 10 MB per file
  files: 5,
};

// Upload lampiran tugas Guru
const assignmentUpload = multer({
  storage: createStorage(assignmentDirectory),
  fileFilter,
  limits: uploadLimits,
});

// Upload jawaban Murid
const submissionUpload = multer({
  storage: createStorage(submissionDirectory),
  fileFilter,
  limits: uploadLimits,
});

module.exports = {
  assignmentUpload,
  submissionUpload,
};
