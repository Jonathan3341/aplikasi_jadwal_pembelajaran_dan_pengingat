# Aplikasi Jadwal Pembelajaran dan Pengingat

Aplikasi Jadwal Pembelajaran dan Pengingat merupakan aplikasi berbasis Flutter dengan backend Node.js dan database SQLite. Aplikasi ini dikembangkan untuk membantu pengelolaan jadwal pembelajaran dan pengingat kegiatan akademik.

## 1. Teknologi

**Frontend**
- Flutter
- Dart
- Material Design

**Backend**
- Node.js
- Express.js
- SQLite
- JSON Web Token (JWT)
- bcrypt

## 2. Fitur Utama

### Autentikasi Pengguna
- Registrasi mahasiswa.
- Login menggunakan email dan password.
- Enkripsi password menggunakan bcrypt.
- Autentikasi menggunakan JWT.
- Access token dan refresh token.
- Logout.
- Pembagian hak akses berdasarkan role: Murid, Guru, dan Admin.

### Fitur Akademik
- Manajemen kelas akademik.
- Pembagian mahasiswa ke kelas.
- Manajemen jadwal pembelajaran.
- Pengingat jadwal.

## 3. Struktur Proyek

```text
aplikasi_jadwal_pembelajaran_dan_pengingat/
│
├── frontend/
│   ├── lib/
│   ├── android/
│   ├── web/
│   └── pubspec.yaml
│
├── backend/
│   ├── src/
│   │   ├── config/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── routes/
│   │   └── services/
│   ├── database/
│   ├── package.json
│   └── .env.example
│
├── .gitignore
└── README.md
```

## 4. Persyaratan Sistem

Pastikan perangkat sudah memiliki:
- Flutter SDK dan Dart SDK.
- Node.js dan npm.
- Git.
- Google Chrome.

## 5. Cara Mengunduh Proyek

Clone repository:

```bash
git clone https://github.com/Jonathan3341/aplikasi_jadwal_pembelajaran_dan_pengingat.git
```

Masuk ke folder proyek:

```bash
cd aplikasi_jadwal_pembelajaran_dan_pengingat
```

## 6. Menjalankan Backend

Masuk ke folder backend:

```bash
cd backend
```

Install dependency:

```bash
npm install
```

Buat file konfigurasi:

Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Buka `.env` dan isi konfigurasi berikut:

```dotenv
PORT=5000
NODE_ENV=development
CLIENT_ORIGIN=http://localhost:5001

JWT_ACCESS_SECRET=ISI_SECRET_ACAK
JWT_REFRESH_SECRET=ISI_SECRET_ACAK_BERBEDA

ACCESS_TOKEN_EXPIRES=15m
REFRESH_TOKEN_DAYS=7

ADMIN_NAME=
ADMIN_EMAIL=
ADMIN_PASSWORD=
```

Generate dua secret JWT dengan perintah Node.js berikut. Jalankan masing-masing perintah satu kali:

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

Masukkan hasil yang berbeda ke `JWT_ACCESS_SECRET` dan `JWT_REFRESH_SECRET`.

Jalankan backend:

```bash
npm start
```

Backend berjalan pada:

```text
http://localhost:5000
```

Database SQLite akan dibuat secara otomatis ketika backend pertama kali dijalankan.

Untuk memeriksa server, buka alamat tersebut melalui browser. Respons yang diharapkan:

```json
{
  "message": "Jadwal Pembelajaran API is running."
}
```

## 7. Menjalankan Frontend

Buka terminal baru dan masuk ke folder utama proyek:

```bash
cd aplikasi_jadwal_pembelajaran_dan_pengingat/frontend
```

Install dependency:

```bash
flutter pub get
```

Jalankan aplikasi melalui Chrome:

```bash
flutter run -d chrome --web-port=5001
```

Buka aplikasi:

```text
http://localhost:5001
```

Pastikan backend tetap berjalan pada terminal pertama.

## 8. Pengujian Register dan Login

Fitur utama yang dapat diuji:

1. Buka aplikasi melalui browser.
2. Pilih halaman Register.
3. Isi nama, NIM, jurusan, email, dan password.
4. Tekan tombol Register.
5. Pastikan proses registrasi berhasil.
6. Kembali ke halaman Login.
7. Masukkan email dan password yang telah didaftarkan.
8. Tekan tombol Login.
9. Pastikan pengguna berhasil masuk ke halaman utama.
10. Uji Logout dan Login kembali.

Registrasi publik secara otomatis memberikan role Murid.

## 9. Membuat Akun Admin (Opsional)

Untuk mencoba fitur administrasi, isi variabel `ADMIN_NAME`, `ADMIN_EMAIL`, dan `ADMIN_PASSWORD` pada `.env`.

Kemudian jalankan dari folder backend:

```bash
npm run create-admin
```

Gunakan email dan password tersebut untuk masuk sebagai Admin.

## 10. Konfigurasi Alamat Backend

| Platform | Alamat Backend |
|---|---|
| Flutter Web | `http://localhost:5000` |
| Android Emulator | `http://10.0.2.2:5000` |

Untuk perangkat fisik atau jaringan berbeda, alamat backend perlu disesuaikan dengan alamat server yang digunakan.

## 11. Keamanan

- Password pengguna disimpan dalam bentuk hash menggunakan bcrypt.
- Sistem menggunakan JWT untuk autentikasi.
- Registrasi publik tidak memberikan hak akses Admin.
- File `.env` tidak disertakan dalam repository.
- Database lokal tidak disertakan dalam repository.
- Secret JWT harus dibuat sendiri pada setiap lingkungan instalasi.

---

**Proyek Aplikasi Jadwal Pembelajaran dan Pengingat**