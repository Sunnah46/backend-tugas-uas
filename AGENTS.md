# AGENTS.md

Repo for **Evently**, a mobile event registration & management app (participants + admin). Stack: **Flutter** app (`mobile/`) + **Laravel 13 API** (`backend/`) + **MySQL 8** (`evently`).

## Source of truth
- `planning_aplikasi_mobile.md` — features, screen structure, user flows, and the **API endpoint design (section 7)**. The Laravel routes in `backend/routes/api.php` implement these.
- `evently_database.sql` — canonical MySQL/MariaDB schema; Laravel migrations mirror it (deviations below are intentional).

## Layout
- `backend/` — Laravel 13 + Sanctum token auth. Entry: `routes/api.php`, `bootstrap/app.php`.
- `mobile/` — Flutter app (Material 3, Provider, `http`). API base URL: `lib/config/api_config.dart` (Android emulator → `10.0.2.2:8000`, otherwise `127.0.0.1:8000`).
- `evently_database.sql`, `planning_aplikasi_mobile.md` — planning docs.

## Commands
- MySQL (Laragon): `"D:\laragon\bin\mysql\mysql-8.4.3-winx64\bin\mysqld.exe"` then `mysql -u root`. Root has no password.
- Backend: `cd backend; composer install; php artisan serve --port=8000`
- Backend verify: `php artisan migrate:fresh --seed` (seeds 5 categories + `admin@evently.com` / `password`).
- Flutter: `cd mobile; flutter pub get; flutter analyze; flutter test`
- Run app: `flutter run -d windows` (or chrome/edge). Android needs `10.0.2.2` and cleartext HTTP is already enabled in the manifest.
- Tests: `flutter test` — the splash test asserts the app boots; no backend needed (SharedPreferences is mocked).

## Database facts
- 6 tables: `users`, `categories`, `events`, `registrations`, `tickets`, `notifications`.
- Relationships: `events.category_id → categories.id`, `registrations.user_id → users.id`, `registrations.event_id → events.id`, `tickets.registration_id → registrations.id`, `notifications.user_id → users.id`. All FKs are `CASCADE`.
- Deviations from `.sql` (verified in migrations): `registrations` has `UNIQUE (user_id, event_id)`; `quota = 0` means **unlimited** (enforced in `RegistrationController@store`, counts statuses ≠ `Ditolak`). Keep both files in sync if you change the schema.

## Critical gotcha: Indonesian enum values
Enum/status values are **Indonesian**, not English. Any API, query, or validation that touches these must use the exact strings:
- `users.role`: `'admin'` | `'user'` (default `'user'`)
- `events.status`: `'Aktif'` | `'Selesai'` | `'Ditutup'` (default `'Aktif'`)
- `registrations.status`: `'Menunggu'` | `'Diterima'` | `'Ditolak'` (default `'Menunggu'`)
- `notifications.is_read` is BOOLEAN (default FALSE); no enum.

## Conventions
- Docs, UI copy, API responses, and comments are in Indonesian.
- Laravel 13 uses PHP attributes (`#[Fillable]`, `#[Hidden]`) on models instead of `$fillable`/`$hidden` — follow the existing models.
- Auth is Sanctum bearer tokens (not JWT). Flutter sends `Authorization: Bearer <token>`.
- Business rules: tickets auto-generate on `Diterima`; notifications auto-create on accept/reject; only `admin` may CRUD events/categories and change registration status.
- No CI/lint/test tooling on the Laravel side — verify with `php artisan route:list` and manual API calls; Flutter side uses `flutter analyze` + `flutter test`.
