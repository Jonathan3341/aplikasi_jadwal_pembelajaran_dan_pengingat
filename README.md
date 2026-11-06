# Aplikasi Jadwal Pembelajaran dan Pengingat

Aplikasi Jadwal Pembelajaran dan Pengingat merupakan aplikasi yang dibuat untuk membantu mahasiswa melihat jadwal perkuliahan dan mengatur pengingat kegiatan akademik. Aplikasi ini dikembangkan menggunakan Flutter sebagai frontend, Node.js sebagai backend, dan SQLite sebagai database.

## Teknologi yang Digunakan

Frontend menggunakan Flutter dan Dart. Backend menggunakan Node.js, Express.js, dan SQLite. Sistem autentikasi menggunakan JSON Web Token (JWT), sedangkan password pengguna diamankan menggunakan bcrypt.

## Fitur Aplikasi

Aplikasi memiliki fitur registrasi dan login pengguna, autentikasi JWT, refresh token, logout, serta pembagian hak akses berdasarkan role Murid, Guru, dan Admin.

Fitur akademik meliputi manajemen kelas, pembagian mahasiswa ke kelas, pengelolaan jadwal pembelajaran, dan pengingat jadwal.

## Persiapan

Sebelum menjalankan aplikasi, pastikan komputer sudah memiliki Flutter SDK, Dart SDK, Node.js, npm, Git, dan Google Chrome.

Unduh proyek melalui repository GitHub, kemudian buka folder aplikasi_jadwal_pembelajaran_dan_pengingat.

## Menjalankan Backend

Buka terminal dan masuk ke folder backend. Jalankan npm install untuk menginstal dependency yang diperlukan.

Buat file konfigurasi lokal dengan menyalin .env.example menjadi .env menggunakan perintah Copy-Item .env.example .env melalui PowerShell.

Buka file .env dan sesuaikan konfigurasi berikut:

- PORT: 5000
- NODE_ENV: development
- CLIENT_ORIGIN: http://localhost:5001
- JWT_ACCESS_SECRET: secret acak untuk access token
- JWT_REFRESH_SECRET: secret acak yang berbeda untuk refresh token
- ACCESS_TOKEN_EXPIRES: 15m
- REFRESH_TOKEN_DAYS: 7

Secret JWT dapat dibuat menggunakan Node.js dengan perintah node -e "console.log(require('crypto').randomBytes(32).toString('hex'))". Jalankan dua kali untuk mendapatkan dua secret yang berbeda.

Setelah konfigurasi selesai, jalankan backend menggunakan npm start. Backend berjalan pada alamat http://localhost:5000.

Database SQLite akan dibuat secara otomatis ketika backend pertama kali dijalankan.

## Menjalankan Frontend

Buka terminal baru dan masuk ke folder frontend. Jalankan flutter pub get untuk menginstal dependency Flutter.

Jalankan aplikasi menggunakan perintah flutter run -d chrome --web-port=5001.

Aplikasi dapat diakses melalui browser pada alamat http://localhost:5001. Pastikan backend tetap berjalan ketika frontend digunakan.

## Pengujian Registrasi dan Login

Buka aplikasi melalui browser, kemudian pilih halaman Register.

Masukkan nama, NIM, jurusan, email, dan password. Setelah registrasi berhasil, kembali ke halaman Login dan masukkan email serta password yang telah didaftarkan.

Jika login berhasil, pengguna akan diarahkan ke halaman utama aplikasi. Pengguna juga dapat melakukan logout dan login kembali menggunakan akun yang sama.

Registrasi publik secara otomatis memberikan role Murid.

## Akun Admin

Apabila ingin mencoba fitur administrasi, akun Admin dapat dibuat melalui proses terpisah.

Isi ADMIN_NAME, ADMIN_EMAIL, dan ADMIN_PASSWORD pada file .env, kemudian jalankan npm run create-admin dari folder backend.

## Konfigurasi Koneksi

Untuk Flutter Web, alamat backend yang digunakan adalah http://localhost:5000.

Untuk Android Emulator, alamat backend yang digunakan adalah http://10.0.2.2:5000.

## Catatan

File .env dan database lokal tidak disertakan dalam repository. Setiap pengguna perlu membuat konfigurasi .env sendiri sebelum menjalankan backend.

Registrasi umum hanya memberikan hak akses Murid. Akun Admin dibuat melalui proses administrasi terpisah.
