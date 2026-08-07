# Perencanaan Pembuatan Aplikasi Mobile Evently

## 1. Ringkasan Proyek
Aplikasi mobile Evently adalah platform pendaftaran dan manajemen event. Sistem akan mendukung pengguna sebagai peserta dan admin untuk mengelola event, pendaftaran, tiket, dan notifikasi.

## 2. Tujuan Utama
- Menampilkan daftar event berdasarkan kategori
- Memungkinkan pengguna mendaftar event
- Mengelola status pendaftaran
- Menghasilkan tiket dan QR code
- Mengirim notifikasi ke pengguna
- Admin mengatur kategori, event, dan pendaftaran

## 3. Basis Data dan Entitas Utama
Berdasarkan `evently_database.sql`, ada 6 entitas utama:
1. `users`
2. `categories`
3. `events`
4. `registrations`
5. `tickets`
6. `notifications`

### Relasi Utama
- `events.category_id` -> `categories.id`
- `registrations.user_id` -> `users.id`
- `registrations.event_id` -> `events.id`
- `tickets.registration_id` -> `registrations.id`
- `notifications.user_id` -> `users.id`

## 4. Fitur Aplikasi Mobile
### 4.1. Autentikasi & Profil
- Registrasi akun baru
- Login menggunakan email dan password
- Logout
- Lihat dan edit profil pengguna
- Role `admin` vs `user`

### 4.2. Event & Kategori
- Daftar event terbaru dan populer
- Filter event berdasarkan kategori
- Cari event berdasarkan judul atau lokasi
- Lihat detail event lengkap
- Status event: `Aktif`, `Selesai`, `Ditutup`

### 4.3. Pendaftaran & Tiket
- Daftar ke event
- Lihat status pendaftaran: `Menunggu`, `Diterima`, `Ditolak`
- Batasi pendaftaran jika kuota penuh
- Buat tiket otomatis pada pendaftaran diterima
- Tampilkan kode tiket dan QR code di aplikasi

### 4.4. Notifikasi
- Terima notifikasi saat pendaftaran disetujui/ditolak
- Notifikasi perubahan status event
- Tandai notifikasi sebagai dibaca/belum dibaca

### 4.5. Admin Panel Mobile
- Kelola kategori event
- Kelola event: tambah, edit, hapus
- Verifikasi pendaftaran peserta
- Lihat statistik dasar event dan pendaftaran

## 5. Struktur Screen Mobile
1. Splash Screen
2. Login / Register
3. Home / Beranda
4. Daftar Event
5. Detail Event
6. Form Pendaftaran Event
7. Dashboard User
   - Riwayat Pendaftaran
   - Tiket Saya
   - Notifikasi
8. Dashboard Admin
   - Kelola Event
   - Kelola Kategori
   - Kelola Pendaftaran
9. Profil Pengguna
10. Halaman Notifikasi

## 6. Alur Pengguna
### Alur User Biasa
1. Buka aplikasi -> login/register
2. Melihat event aktif di beranda
3. Memilih kategori atau mencari event
4. Membuka detail event
5. Menekan tombol daftar
6. Menunggu konfirmasi admin
7. Jika diterima, tiket muncul di menu `Tiket Saya`
8. Mendapatkan notifikasi terkait status pendaftaran

### Alur Admin
1. Login sebagai admin
2. Membuka panel admin
3. Menambah atau mengedit kategori
4. Menambah atau mengedit event
5. Memeriksa daftar pendaftaran
6. Menyetujui atau menolak pendaftaran
7. Notifikasi dikirim ke peserta

## 7. Endpoints API (Desain Awal)
### Auth
- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`
- `PUT /auth/profile`

### Kategori
- `GET /categories`
- `POST /categories`
- `PUT /categories/:id`
- `DELETE /categories/:id`

### Event
- `GET /events`
- `GET /events/:id`
- `POST /events`
- `PUT /events/:id`
- `DELETE /events/:id`

### Pendaftaran
- `GET /registrations`
- `GET /registrations/:id`
- `POST /registrations`
- `PUT /registrations/:id`
- `DELETE /registrations/:id`

### Tiket
- `GET /tickets`
- `GET /tickets/:id`

### Notifikasi
- `GET /notifications`
- `PUT /notifications/:id/read`
- `POST /notifications`

## 8. Teknologi yang Disarankan
- Platform: React Native / Flutter
- Backend: Node.js + Express / Laravel / Django
- Database: MySQL / MariaDB (sesuai SQL file)
- Autentikasi: JWT
- Penyimpanan gambar event: Cloud storage / server local
- Notifikasi: push notification (Firebase Cloud Messaging) atau in-app notifications

## 9. User Story & Prioritas
### Prioritas Tinggi
- Registrasi/login pengguna
- Daftar event dan detail event
- Pendaftaran event
- Admin verifikasi pendaftaran
- Generate tiket ketika pendaftaran diterima

### Prioritas Sedang
- Manajemen kategori
- Filter dan pencarian event
- Lihat riwayat pendaftaran
- Notifikasi in-app

### Prioritas Rendah
- Statistik event admin
- Export data pendaftaran
- Update status event otomatis

## 10. Milestone & Timeline
### Milestone 1: Setup & Autentikasi
- Setup proyek mobile
- Setup backend API dan database
- Implementasi registrasi/login
- Halaman profil dan autentikasi

### Milestone 2: Event & Kategori
- Implementasi daftar kategori
- CRUD event
- Tampilan daftar dan detail event

### Milestone 3: Pendaftaran & Tiket
- Form pendaftaran event
- Simpan data registrasi
- Approve/reject oleh admin
- Generate tiket dan QR code

### Milestone 4: Notifikasi & Dashboard
- Implementasi notifikasi
- Halaman notifikasi user
- Dashboard admin untuk kelola pendaftaran

### Milestone 5: Pengujian & Peluncuran
- Uji fungsi end-to-end
- Perbaikan UI/UX
- Dokumentasi API dan deployment

## 11. Catatan Tambahan
- Pastikan validasi pada input user untuk email, password, dan kuota event
- Kelola error saat kuota event penuh atau event sudah ditutup
- Pastikan hanya `admin` yang bisa menghapus atau mengubah event/ kategori
- Gunakan timestamp `created_at` dan `updated_at` untuk audit serta riwayat
