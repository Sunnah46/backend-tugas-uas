# LAPORAN STRUKTUR LENGKAP APLIKASI EVENTLY

**Aplikasi:** Evently — Aplikasi Mobile Pendaftaran & Manajemen Event (Peserta + Admin)
**Teknologi:** Flutter (mobile) + Laravel 13 (API) + MySQL 8 (database `evently`)
**Lokasi:** `D:\uas pemograman\backend` dan `D:\uas pemograman\mobile`

---

## 1. Ringkasan Arsitektur

```
┌─────────────────────────┐        HTTP/JSON         ┌──────────────────────────┐
│   Aplikasi Flutter       │  ────────────────────►  │   API Laravel 13         │
│   (Android / Web / Win)  │  Authorization: Bearer  │   auth:sanctum            │
│   Material 3, Provider   │        token            │   app/Http/Controllers    │
└─────────────────────────┘                         └──────────┬───────────────┘
                                                               │ Eloquent
                                                               ▼
                                                     ┌────────────────────┐
                                                     │  MySQL 8 — DB:      │
                                                     │  evently (6 tabel)  │
                                                     └────────────────────┘
```

- Autentikasi: **Sanctum bearer token** (bukan JWT).
- Bahasa antarmuka, respons API, dan komentar: **Indonesia**.
- State management mobile: **Provider** (`AuthProvider`) + **ApiService** (singleton).
- Frontend memakai **Material 3**, tema **Navy & Gold**.
- Navigasi mobile: **imperatif** (`Navigator.push`) tanpa named routes.
- Nilai enum memakai string **Indonesia**: `role` (admin/user), `events.status` (Aktif/Selesai/Ditutup), `registrations.status` (Menunggu/Diterima/Ditolak).

---

## 2. Struktur Backend Laravel (`backend/`)

```
backend\
├── app\
│   ├── Http\
│   │   └── Controllers\
│   │       ├── Controller.php                        (base controller)
│   │       └── Api\
│   │           ├── AuthController.php
│   │           ├── CategoryController.php
│   │           ├── EventController.php
│   │           ├── NotificationController.php
│   │           ├── RegistrationController.php
│   │           └── TicketController.php
│   ├── Models\
│   │   ├── User.php
│   │   ├── Category.php
│   │   ├── Event.php
│   │   ├── Registration.php
│   │   ├── Ticket.php
│   │   └── Notification.php
│   └── Providers\
│       └── AppServiceProvider.php
├── bootstrap\
│   ├── app.php                          (middleware & exception config)
│   └── providers.php
├── config\                              (13 file: app, auth, cache, cors,
│                                        database, filesystems, logging,
│                                        mail, queue, sanctum, services, session)
├── database\
│   ├── factories\  →  UserFactory.php
│   ├── migrations\ (9 file — lihat tabel 4)
│   └── seeders\
│       ├── DatabaseSeeder.php
│       └── CategorySeeder.php
├── routes\
│   ├── api.php       (22 endpoint API)
│   ├── console.php
│   └── web.php
├── tests\
│   ├── Feature\ExampleTest.php
│   └── Unit\ExampleTest.php
└── (root: artisan, composer.json, composer.lock, .env, vite.config.js, ...)
```

**Versi:** Laravel Framework `^13.8` (terpasang v13.24.0), PHP `^8.3`, Sanctum `^4.3`.

---

## 3. Controller Backend (`app/Http/Controllers/Api/`)

| Controller | Fungsi |
|---|---|
| `AuthController` | `register` (akun baru, role default user), `login`, `me` (profil login), `profile` (update nama/HP/password), `logout` (hapus token) |
| `CategoryController` | `index` (daftar), `store`, `update`, `destroy` — CRUD kategori |
| `EventController` | `index` (list + filter category/status/search, paginate 10, non-admin hanya lihat `Aktif`), `show`, `store`/`update`/`destroy` (**admin only**) |
| `RegistrationController` | `index` (admin: semua; user: miliknya), `show`, `store` (daftar event: cek Aktif, duplikat, kuota; `quota=0` = tanpa batas), `update` (ubah status → generate tiket + notifikasi, **admin only**), `destroy` (batalkan) |
| `TicketController` | `index`, `show` — baca tiket (admin semua, user hanya miliknya) |
| `NotificationController` | `index` (milik user), `markRead` (tandai dibaca), `store` (kirim notifikasi, **admin only**) |

**Pola otorisasi:** tidak memakai middleware/Request khusus — setiap controller punya helper private `authorizeAdmin()` (abort 403 bila role ≠ admin) dan pengecekan kepemilikan di dalam method.

**Logika bisnis kunci:**
- Tiket otomatis dibuat saat status pendaftaran → `Diterima` (kode `EVT-<event>-<reg>-<random6>`).
- Notifikasi otomatis dibuat saat status `Diterima`/`Ditolak`.
- `quota = 0` berarti kuota tanpa batas.
- Duplikasi pendaftaran dicegah oleh `UNIQUE(user_id, event_id)` + validasi controller.

---

## 4. Model & Tabel Database

**6 tabel inti** (ditambah tabel framework: users/sessions/cache/jobs/Sanctum):

| Tabel | Kolom utama (fillable) | Relasi |
|---|---|---|
| `users` | `name, email, password, phone, role` (admin/user) | hasMany registrations, hasMany notifications |
| `categories` | `category_name, description` | hasMany events |
| `events` | `category_id, title, description, organizer, location, event_date, start_time, end_time, quota, image, status` | belongsTo category, hasMany registrations |
| `registrations` | `user_id, event_id, registration_date, status` + `UNIQUE(user_id, event_id)` | belongsTo user/event, hasOne ticket |
| `tickets` | `registration_id, ticket_code, qr_code` | belongsTo registration |
| `notifications` | `user_id, title, message, is_read` (boolean, `updated_at = null`) | belongsTo user |

Semua foreign key memakai `CASCADE`. Model memakai sintaks atribut PHP (`#[Fillable]`, `#[Hidden]`) gaya Laravel 13.

**Seeder:**
- `CategorySeeder` — 5 kategori: Seminar, Workshop, Webinar, Lomba, Pelatihan.
- `DatabaseSeeder` — admin `admin@evently.com` / password `password`.

---

## 5. Endpoint API (`routes/api.php`, total 22)

**Publik (tanpa auth):**
| Metode | Endpoint | Fungsi |
|---|---|---|
| POST | `/api/auth/register` | Daftar akun |
| POST | `/api/auth/login` | Login |

**Perlu token (`auth:sanctum`):**
| Metode | Endpoint | Fungsi |
|---|---|---|
| GET | `/api/auth/me` | Profil user login |
| PUT | `/api/auth/profile` | Update profil |
| POST | `/api/auth/logout` | Logout |
| GET/POST | `/api/categories` | Daftar / buat kategori |
| PUT/DELETE | `/api/categories/{id}` | Ubah / hapus kategori |
| GET | `/api/events` | Daftar event (filter+paginate) |
| GET | `/api/events/{id}` | Detail event |
| POST/PUT/DELETE | `/api/events` `/api/events/{id}` | Buat / ubah / hapus event (admin) |
| GET | `/api/registrations` | Daftar pendaftaran |
| GET | `/api/registrations/{id}` | Detail pendaftaran |
| POST/PUT/DELETE | `/api/registrations` `/api/registrations/{id}` | Daftar / ubah status (admin) / batal |
| GET | `/api/tickets` | Daftar tiket |
| GET | `/api/tickets/{id}` | Detail tiket |
| GET | `/api/notifications` | Daftar notifikasi |
| PUT | `/api/notifications/{id}/read` | Tandai dibaca |
| POST | `/api/notifications` | Kirim notifikasi (admin) |

---

## 6. Struktur Aplikasi Flutter (`mobile/lib/`, 31 file Dart)

```
lib\
├── main.dart
├── config\
│   └── api_config.dart                     (base URL API per platform)
├── models\
│   ├── user.dart                           (id, name, email, phone, role; getter isAdmin)
│   ├── category.dart                       (id, categoryName, description)
│   ├── event.dart                          (id, categoryId, title, deskripsi, organizer,
│   │                                        location, eventDate, start/endTime, quota,
│   │                                        image, status, registeredCount, category;
│   │                                        getter isOpen, isFull)
│   ├── event_theme.dart                    (8 tema gambar preset: Navy, Gold, Teal,
│   │                                        Royal, Maroon, Forest, Sunset, Ocean)
│   ├── paginated.dart                      (wrapper paginasi API)
│   ├── registration.dart                   (id, userId, eventId, registrationDate,
│   │                                        status, event, user, ticket)
│   ├── ticket.dart                         (id, registrationId, ticketCode, qrCode,
│   │                                        eventId, eventTitle)
│   └── app_notification.dart               (id, userId, title, message, isRead, createdAt)
├── providers\
│   └── auth_provider.dart                  (ChangeNotifier — kelola token & sesi via
│                                            SharedPreferences; restoreSession, login,
│                                            register, updateProfile, logout)
├── screens\
│   ├── splash_screen.dart                  (redirect sesuai sesi/role)
│   ├── home_screen.dart                    (NavigationBar 5 tab + badge notifikasi
│   │                                        + tombol Riwayat)
│   ├── events_screen.dart                  (daftar event: search, filter kategori,
│   │                                        infinite scroll, pull-to-refresh)
│   ├── event_detail_screen.dart            (detail + tombol daftar dengan konfirmasi)
│   ├── registrations_screen.dart           (tab Pendaftaran user)
│   ├── tickets_screen.dart                 (tab Tiket dengan QR code)
│   ├── notifications_screen.dart           (tab Notifikasi + dialog detail)
│   ├── riwayat_screen.dart                 (Riwayat pendaftaran + tombol hapus)
│   ├── profile_screen.dart                 (tab Profil: avatar, edit nama/HP, logout)
│   ├── auth\
│   │   ├── login_screen.dart               (login: email+password, gradien navy)
│   │   └── register_screen.dart            (daftar akun dengan validasi)
│   └── admin\
│       ├── admin_home_screen.dart          (dashboard admin + 4 menu + logout)
│       ├── manage_events_screen.dart       (CRUD event admin)
│       ├── event_form_screen.dart          (form tambah/edit event + pemilih tema
│       │                                    gambar grid)
│       ├── manage_categories_screen.dart   (CRUD kategori via dialog)
│       └── manage_registrations_screen.dart(verifikasi: Terima/Tolak + Hapus Riwayat)
├── services\
│   ├── api_service.dart                    (singleton HTTP: 20+ method API, lempar
│   │                                        ApiException, header Authorization)
│   └── api_exception.dart                  (exception API dengan message & statusCode)
└── widgets\
    ├── event_card.dart                     (kartu event reusable)
    ├── event_image.dart                    (gambar event: asset tema / URL / placeholder)
    └── status_badge.dart                   (badge status berwarna)
```

**Aset:** `mobile/assets/images/event_themes/` → 8 gambar tema PNG.
**Test:** `mobile/test/widget_test.dart` (membuktikan aplikasi boot ke splash).

---

## 7. Alur & Peran Pengguna

### Peserta (role `user`)
1. **Register** → otomatis login → masuk `HomeScreen`.
2. Tab **Beranda**: cari event, filter kategori, buka detail, tekan **"Daftar Sekarang"** (status awal `Menunggu`).
3. Tab **Pendaftaran**: lihat status pendaftaran.
4. Saat admin menerima → tiket otomatis dibuat → tab **Tiket** menampilkan kartu tiket + **QR code**.
5. Tab **Notifikasi**: pemberitahuan diterima/ditolak (pop-up otomatis untuk yang belum dibaca + badge jumlah).
6. **Riwayat** (ikon AppBar): lihat riwayat pendaftaran + hapus.
7. **Profil**: ubah nama/HP, logout.

### Admin (role `admin`)
1. Login `admin@evently.com` / `password` → masuk `AdminHomeScreen` (dashboard).
2. **Kelola Event**: tambah/edit/hapus event, pilih **tema gambar** dari 8 preset.
3. **Kelola Kategori**: tambah/edit/hapus kategori (kategori dihapus → event terkait ikut terhapus).
4. **Kelola Pendaftaran**: terima/tolak pendaftaran (`Diterima` → tiket + notifikasi otomatis), hapus riwayat.
5. **Profil**: ubah nama/HP, logout.

---

## 8. Tema (Material 3, Navy & Gold) — `lib/main.dart`

| Komponen | Nilai |
|---|---|
| Seed / primary | `#1B2A4A` / `#16224E` (navy) |
| Secondary | `#C9A227` (emas) |
| secondaryContainer | `#F6E9C8` |
| AppBar | latar `#16224E`, foreground putih |
| NavigationBar indicator | `#F6E9C8` |
| Input decoration | `OutlineInputBorder` |
| Card | elevation 1, `Clip.antiAlias` |
| Gradient splash/login | `#16224E → #2A3A66` |

---

## 9. Dependensi Utama

**Backend (`composer.json`):** `laravel/framework ^13.8`, `laravel/sanctum ^4.3`, `laravel/tinker ^3.0`; dev: `phpunit`, `laravel/pint`, `mockery`, `nunomaduro/collision`.

**Mobile (`pubspec.yaml`):** `http ^1.2.2`, `provider ^6.1.2`, `shared_preferences ^2.3.3`, `intl ^0.19.0`, `qr_flutter ^4.1.0`, `image_picker ^1.1.2`; dev: `flutter_test`, `flutter_lints ^6.0.0`.

---

## 10. Cara Menjalankan

1. **MySQL** (Laragon): `D:\laragon\bin\mysql\mysql-8.4.3-winx64\bin\mysqld.exe`
2. **Backend**: `cd backend` → `php artisan serve --port=8000` (verifikasi: `php artisan migrate:fresh --seed` bila perlu)
3. **Aplikasi**: `cd mobile` → `flutter run -d chrome` (atau `-d windows`, `-d emulator-5554`)

**Akun default:** admin `admin@evently.com` / `password`; peserta dibuat via halaman daftar.

---

## 11. Catatan Penting

- `quota = 0` = kuota tanpa batas (dihitung dari pendaftaran berstatus ≠ `Ditolak`).
- Enum/status memakai string Indonesia — harus persis (`Aktif`, `Menunggu`, `Diterima`, `Ditolak`, `Selesai`, `Ditutup`).
- CORS aktif untuk web (`config/cors.php`: semua origin/method/header diizinkan).
- `ApiConfig.baseUrl`: emulator Android → `10.0.2.2:8000/api`; web/desktop → `127.0.0.1:8000/api`.
- Gambar event disimpan sebagai path asset preset tema (`assets/images/event_themes/...`), bukan file upload.
- Tidak ada named routes di Flutter; navigasi imperatif `MaterialPageRoute`.
- Tidak ada middleware otorisasi khusus; admin check manual di tiap controller.

---

# LAMPIRAN A — Diagram ERD (Entity Relationship Diagram)

## A.1 Diagram Relasi

```
┌───────────────┐
│   users       │
│───────────────│
│ PK id         │
│ name          │
│ email (UQ)    │
│ password      │
│ phone         │
│ role [enum]   │  1 ──────────── ∞        ┌──────────────────┐
└───────┬───────┘        ───────────        │ categories       │
        │                                  │──────────────────│
        │ 1                            1   │ PK id            │
        │                                  │ category_name    │
        ▼ ∞                                │ description      │
┌─────────────────────────┐                └─────────┬────────┘
│  registrations          │                    ∞     │ 1
│─────────────────────────│                  ────────┘
│ PK id                   │                   1
│ FK user_id ─────────────┤                ┌──────────▼──────┐
│ FK event_id ────────────┤                │ events          │
│ registration_date       │                │─────────────────│
│ status [enum]           │                │ PK id           │
│ UNIQUE (user_id,event_id)│               │ FK category_id  │
└──────────────┬──────────┘                │ title           │
               │ 1                         │ description     │
               │ ∞                         │ organizer       │
               ▼                           │ location        │
      ┌──────────────────┐                 │ event_date      │
      │  tickets          │                 │ start_time      │
      │──────────────────│                 │ end_time        │
      │ PK id             │                 │ quota           │
      │ FK registration_id│                 │ image           │
      │ ticket_code (UQ)  │                 │ status [enum]   │
      │ qr_code           │                 └─────────────────┘
      └──────────────────┘

┌───────────────┐
│ notifications │
│───────────────│
│ PK id         │
│ FK user_id ───┼──────► users.id
│ title         │
│ message       │
│ is_read (bool)│
│ created_at    │
└───────────────┘
```

## A.2 Kardinalitas

| Relasi | Kiri → Kanan | Jenis |
|---|---|---|
| users → registrations | 1 → ∞ | Satu user bisa daftar banyak event |
| events → registrations | 1 → ∞ | Satu event bisa didaftar banyak user |
| categories → events | 1 → ∞ | Satu kategori menampung banyak event |
| registrations → tickets | 1 → 0..1 | Satu pendaftaran punya paling banyak satu tiket (dibuat saat `Diterima`) |
| users → notifications | 1 → ∞ | Satu user menerima banyak notifikasi |

## A.3 Detail Kolom per Tabel (dari migrasi)

### `users`
| Kolom | Tipe | Aturan |
|---|---|---|
| id | BIGINT UNSIGNED | PK, auto increment |
| name | VARCHAR(100) | wajib |
| email | VARCHAR(100) | wajib, **UNIQUE** |
| password | VARCHAR(255) | wajib, hash |
| phone | VARCHAR(20) | nullable |
| role | ENUM('admin','user') | default `user` |
| created_at / updated_at | TIMESTAMP | timestamps |

### `categories`
| Kolom | Tipe | Aturan |
|---|---|---|
| id | BIGINT UNSIGNED | PK |
| category_name | VARCHAR(100) | wajib |
| description | TEXT | nullable |
| created_at / updated_at | TIMESTAMP | timestamps |

### `events`
| Kolom | Tipe | Aturan |
|---|---|---|
| id | BIGINT UNSIGNED | PK |
| category_id | BIGINT UNSIGNED | FK → categories.id, **CASCADE delete** |
| title | VARCHAR(150) | wajib |
| description | TEXT | nullable |
| organizer | VARCHAR(100) | nullable |
| location | VARCHAR(150) | nullable |
| event_date | DATE | nullable |
| start_time | TIME | nullable |
| end_time | TIME | nullable |
| quota | INTEGER | default 0 (= tanpa batas) |
| image | VARCHAR(255) | nullable (path asset tema) |
| status | ENUM('Aktif','Selesai','Ditutup') | default `Aktif` |
| created_at / updated_at | TIMESTAMP | timestamps |

### `registrations`
| Kolom | Tipe | Aturan |
|---|---|---|
| id | BIGINT UNSIGNED | PK |
| user_id | BIGINT UNSIGNED | FK → users.id, **CASCADE delete** |
| event_id | BIGINT UNSIGNED | FK → events.id, **CASCADE delete** |
| registration_date | DATE | nullable |
| status | ENUM('Menunggu','Diterima','Ditolak') | default `Menunggu` |
| created_at / updated_at | TIMESTAMP | timestamps |
| — | — | **UNIQUE (user_id, event_id)** — cegah daftar ganda |

### `tickets`
| Kolom | Tipe | Aturan |
|---|---|---|
| id | BIGINT UNSIGNED | PK |
| registration_id | BIGINT UNSIGNED | FK → registrations.id, **CASCADE delete** |
| ticket_code | VARCHAR(50) | wajib, **UNIQUE** (format `EVT-<event>-<reg>-<random>`) |
| qr_code | VARCHAR(255) | nullable |
| created_at / updated_at | TIMESTAMP | timestamps |

### `notifications`
| Kolom | Tipe | Aturan |
|---|---|---|
| id | BIGINT UNSIGNED | PK |
| user_id | BIGINT UNSIGNED | FK → users.id, **CASCADE delete** |
| title | VARCHAR(100) | nullable |
| message | TEXT | nullable |
| is_read | BOOLEAN | default FALSE |
| created_at | TIMESTAMP | `useCurrent()`, **tanpa updated_at** |

---

# LAMPIRAN B — Laporan Per-Modul

## B.1 Modul Autentikasi

**Backend:** `AuthController.php`
**Mobile:** `auth/login_screen.dart`, `auth/register_screen.dart`, `providers/auth_provider.dart`, `screens/splash_screen.dart`

**Endpoint:**
| Metode | Endpoint | Deskripsi |
|---|---|---|
| POST | `/api/auth/register` | Buat akun (role `user`), langsung kembalikan token |
| POST | `/api/auth/login` | Verifikasi email+password (Hash::check), kembalikan token Sanctum |
| GET | `/api/auth/me` | Data user yang sedang login |
| PUT | `/api/auth/profile` | Update nama/phone/password |
| POST | `/api/auth/logout` | Hapus token aktif |

**Alur:**
1. User login/register → backend mengembalikan `token` + data `user`.
2. `AuthProvider.login()` menyimpan token di `SharedPreferences` (key `auth_token`, `auth_user`) dan menyetel `ApiService.instance.token`.
3. `SplashScreen` memanggil `restoreSession()` → redirect sesuai status: admin → `AdminHomeScreen`, user → `HomeScreen`, tanpa sesi → `LoginScreen`.
4. Bila `me()` gagal dengan 401 → sesi dihapus (logout otomatis); gagal karena server offline → sesi tetap dipertahankan.
5. `logout()` memanggil API lalu menghapus sesi lokal → kembali ke `LoginScreen`.

**Validasi register (mobile):** nama wajib, email regex valid, password min 8 karakter, konfirmasi password harus cocok.

---

## B.2 Modul Kategori

**Backend:** `CategoryController.php`
**Mobile:** `admin/manage_categories_screen.dart`

**Endpoint:**
| Metode | Endpoint | Deskripsi |
|---|---|---|
| GET | `/api/categories` | Daftar kategori (urut abjad) |
| POST | `/api/categories` | Buat kategori (unique `category_name`) |
| PUT | `/api/categories/{id}` | Ubah kategori (unique, ignore id sendiri) |
| DELETE | `/api/categories/{id}` | Hapus kategori (event terkait ikut terhapus — CASCADE) |

**UI:** `manage_categories_screen.dart` — daftar kategori dengan tombol edit/hapus; tambah & edit lewat `AlertDialog` inline. Hapus menampilkan peringatan bahwa event terkait akan ikut terhapus.

**Aturan bisnis:** kategori dihapus → semua event ber-kategori itu ikut terhapus (FK `cascadeOnDelete`), beserta pendaftaran & tiketnya (CASCADE berantai).

---

## B.3 Modul Event

**Backend:** `EventController.php`
**Mobile:** `events_screen.dart`, `event_detail_screen.dart`, `admin/manage_events_screen.dart`, `admin/event_form_screen.dart`, `widgets/event_card.dart`, `widgets/event_image.dart`, `models/event_theme.dart`

**Endpoint:**
| Metode | Endpoint | Deskripsi |
|---|---|---|
| GET | `/api/events` | Daftar event; query: `category_id`, `status`, `search`, `page`; paginate 10 |
| GET | `/api/events/{id}` | Detail event + kategori |
| POST | `/api/events` | Buat event (**admin**) |
| PUT | `/api/events/{id}` | Ubah event (**admin**) |
| DELETE | `/api/events/{id}` | Hapus event (**admin**) |

**Fitur penting:**
- **Filter (index):** non-admin hanya melihat status `Aktif`; admin melihat semua status.
- **Pencarian:** filter `search` cocok pada title, location, organizer.
- **Kuota:** `quota > 0` membatasi jumlah pendaftaran (status ≠ `Ditolak`); `quota = 0` = tanpa batas.
- **Gambar tema:** field `image` menyimpan path asset preset (`assets/images/event_themes/tema_N.png`). `event_form_screen.dart` menampilkan grid 4 kolom pilihan tema (Navy, Gold, Teal, Royal, Maroon, Forest, Sunset, Ocean). `EventImage` menampilkan asset bila cocok dengan tema, `Image.network` bila URL, placeholder gradien bila kosong.

**Form event (admin):** judul, dropdown kategori, deskripsi, penyelenggara, lokasi, date picker + time picker (mulai/selesai), kuota, pemilih tema gambar, status (`Aktif`/`Selesai`/`Ditutup`).

---

## B.4 Modul Pendaftaran (Registration)

**Backend:** `RegistrationController.php`
**Mobile:** `registrations_screen.dart`, `riwayat_screen.dart`, `admin/manage_registrations_screen.dart`

**Endpoint:**
| Metode | Endpoint | Deskripsi |
|---|---|---|
| GET | `/api/registrations` | Admin: semua; user: hanya miliknya |
| GET | `/api/registrations/{id}` | Detail; admin atau pemilik |
| POST | `/api/registrations` | Daftar ke event |
| PUT | `/api/registrations/{id}` | Ubah status (**admin**): Terima/Tolak |
| DELETE | `/api/registrations/{id}` | Batalkan/hapus; admin atau pemilik |

**Alur pendaftaran:**
1. User membuka detail event → tekan **"Daftar Sekarang"** → dialog konfirmasi → `POST /registrations` dengan body `{event_id}`.
2. Backend memvalidasi: event harus `Aktif`, belum pernah didaftar (UNIQUE), dan kuota belum penuh (bila `quota > 0`).
3. Status awal `Menunggu`. `registered_count` dihitung dari pendaftaran berstatus ≠ `Ditolak`.
4. Admin menerima/tolak di `manage_registrations_screen.dart` → `PUT /registrations/{id}`.
5. **`Diterima`** → tiket otomatis dibuat + notifikasi "Pendaftaran diterima".
6. **`Ditolak`** → notifikasi "Pendaftaran ditolak".

**UI user:**
- Tab **Pendaftaran** (`registrations_screen.dart`) — status pendaftaran, pull-to-refresh.
- **Riwayat** (`riwayat_screen.dart`) — dari ikon history di AppBar; sama seperti daftar pendaftaran plus tombol **Hapus** (dialog konfirmasi → `DELETE /registrations/{id}`). Tombol hapus hanya ada di layar Riwayat, bukan di tab Pendaftaran.

---

## B.5 Modul Tiket

**Backend:** `TicketController.php`
**Mobile:** `tickets_screen.dart`

**Endpoint:**
| Metode | Endpoint | Deskripsi |
|---|---|---|
| GET | `/api/tickets` | Admin: semua; user: tiket miliknya |
| GET | `/api/tickets/{id}` | Detail; admin atau pemilik |

**Alur:**
- Tiket **tidak dibuat saat mendaftar**, melainkan saat admin mengubah status pendaftaran menjadi `Diterima` (dalam `RegistrationController@update` → `generateTicket()`).
- Kode tiket format: `EVT-<event_id>-<registration_id>-<random6>`.
- `qr_code` opsional (nullable) — tersedia untuk keperluan QR di masa depan.

**UI:** Tab **Tiket Saya** menampilkan kartu tiket bergradien navy dengan **QR code** (paket `qr_flutter`), kode tiket, dan teks "Tunjukkan kode ini saat check-in". Data `eventId`/`eventTitle` diekstrak dari objek `registration` bertingkat di `Ticket.fromJson`.

---

## B.6 Modul Notifikasi

**Backend:** `NotificationController.php`
**Mobile:** `notifications_screen.dart`, `home_screen.dart` (badge + pop-up)

**Endpoint:**
| Metode | Endpoint | Deskripsi |
|---|---|---|
| GET | `/api/notifications` | Notifikasi milik user login (paginate 20, terbaru dulu) |
| PUT | `/api/notifications/{id}/read` | Tandai dibaca/belum (body `{is_read}`) |
| POST | `/api/notifications` | Kirim notifikasi ke user tertentu (**admin**) |

**Pemicu otomatis (dari modul pendaftaran):**
- Pendaftaran **Diterima** → notifikasi.
- Pendaftaran **Ditolak** → notifikasi.

**UI & perilaku:**
- `home_screen.dart` saat dibuka menampilkan **pop-up daftar notifikasi yang belum dibaca** (`_showUnreadNotifications`).
- Ikon notifikasi di NavigationBar menampilkan **badge jumlah belum dibaca** (`Badge.count`, widget `_NotificationIcon`).
- `notifications_screen.dart` menandai belum-dibaca dengan highlight; **tap** membuka dialog detail sekaligus menandai dibaca (pop-up detail hanya untuk notifikasi belum dibaca — `_showDetails` return early bila `isRead`). Ada toggle baca/belum-baca.

---

## B.7 Modul Dashboard Admin

**Backend:** (tidak ada endpoint khusus — memakai CRUD event/kategori/pendaftaran)
**Mobile:** `admin/admin_home_screen.dart`

**Isi dashboard:**
- Kartu gradien "Kelola Evently" (tema navy-gold).
- 4 menu: **Kelola Event**, **Kelola Kategori**, **Kelola Pendaftaran**, **Profil**.
- AppBar: ikon **Riwayat** (membuka `ManageRegistrationsScreen`) dan ikon **Keluar** (logout langsung).

**Akses admin:** diputuskan dari `AuthProvider.isAdmin` (`role == 'admin'`). Splash & login mengarahkan admin ke `AdminHomeScreen`, sedangkan peserta ke `HomeScreen`.

---

## B.8 Modul Profil & Sesi

**Backend:** `AuthController@profile`
**Mobile:** `profile_screen.dart`

**Isi:**
- Avatar lingkaran berinisial, nama, email, badge peran (Admin/Peserta).
- Form edit nama & nomor HP → `updateProfile()` (PUT `/auth/profile`).
- Tombol **Keluar** → `auth.logout()` → kembali ke `LoginScreen`.

**Catatan:** layar yang sama dipakai admin (dibuka dari dashboard) dan peserta (tab Profil); pada admin dibungkus `Scaffold` dengan AppBar "Profil" di `admin_home_screen.dart`.
