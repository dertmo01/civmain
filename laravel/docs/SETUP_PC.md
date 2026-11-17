# CivilWatch — PC setup (XAMPP MySQL)

How to take the code from GitHub and get it running on a Windows PC with
XAMPP: import one SQL file, start the server, log in as admin, register a
citizen, submit a report.

There are two machines in this project:

| | Android / Termux (development) | PC / XAMPP (testing) |
|---|---|---|
| Database | Termux MariaDB | XAMPP MySQL |
| Code sync | `git push backup main` | `git pull backup main` |
| Web UI | your Termux menu launcher → Brave | browser → `http://127.0.0.1:8000` |
| Flutter | not used (no disk space) | `flutter run -d chrome` |

---

## Prerequisites

- **PHP 8.2 or newer** (this project is developed on PHP 8.5.1)
- **Composer**
- **XAMPP** — only for its MySQL and phpMyAdmin. Apache is *not* required;
  Laravel runs on its own built-in server.
- **Flutter SDK** — only if you want to run the mobile app on the PC
- **Git**
- **Node.js is optional.** Nothing that gets served uses Vite — only the
  stock `resources/views/welcome.blade.php` references `@vite`. Skip it
  unless you touch that file.

---

## Get the code

```bash
git clone https://github.com/dertmo01/civmain.git
cd civmain/laravel
```

Already cloned? `git pull backup main`.

---

## One-time database import

This is the fast path — one file, no artisan commands.

1. Start **MySQL** from the XAMPP Control Panel.
2. Open <http://localhost/phpmyadmin>.
3. Click the **Import** tab.
4. Choose **`civilwatch_FINAL.sql`** (it is in `laravel/`).
5. Click **Go**.

The file creates the database for you (`CREATE DATABASE IF NOT EXISTS
civilwatch`), drops nothing you care about, and loads the schema plus seed
data:

- 15 tables (modern schema only — no legacy `reports`/`notifications`)
- `citizen_reports.status` ENUM **includes `Rejected`** (required for the
  reject-with-notes flow)
- 2 admin accounts, 5 government offices, 2 announcements
- 1 sample citizen, 3 sample reports (2 Rejected, 1 Assigned), 9 activities,
  6 notifications — so every screen has something to show

**Verify the import** (phpMyAdmin → SQL tab):

```sql
SELECT COUNT(*) FROM information_schema.TABLES
 WHERE TABLE_SCHEMA = 'civilwatch';          -- expect 15

SELECT COLUMN_TYPE FROM information_schema.COLUMNS
 WHERE TABLE_SCHEMA = 'civilwatch'
   AND TABLE_NAME  = 'citizen_reports'
   AND COLUMN_NAME = 'status';               -- must contain 'Rejected'
```

**15 is correct at this point.** The next section runs one migration that adds
a 16th table (`sessions`), so you end up with 16.

---

## .env and APP_KEY

`.env` is gitignored, so a fresh clone will not have one:

```bash
cp .env.example .env
php artisan key:generate
```

`.env.example` already points at MySQL/XAMPP:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=civilwatch
DB_USERNAME=root
DB_PASSWORD=
```

XAMPP's default is `root` with an **empty password** — leave `DB_PASSWORD`
empty unless you changed it.

### Then create the `sessions` table

`.env.example` ships `SESSION_DRIVER=database`, but the SQL dump was taken
before the `sessions` migration existed — so a phpMyAdmin import alone leaves
no table for Laravel to store web sessions in. Run:

```bash
php artisan migrate
```

Verified: it runs **exactly one** migration (`create_sessions_table`), creates
the 16th table, and touches no existing rows — your 2 users and 3 sample
reports come through untouched.

**Skip this and `/admin/login` returns 500** (the Blade session driver cannot
write). The HTML/JS dashboard at `/` still works, which is what makes it easy
to miss. `SESSION_DRIVER=file` sidesteps it, but the migration is the fix.

---

## Run the backend

```bash
php artisan serve --host=127.0.0.1 --port=8000
```

Then open:

- <http://127.0.0.1:8000> — the HTML/JS admin dashboard
- <http://127.0.0.1:8000/admin/login> — the Blade admin panel

If you will run the Flutter app from another device on your network, bind to
`0.0.0.0` instead of `127.0.0.1` and use your PC's LAN IPv4.

---

## Alternative: composer setup

If you would rather not click through phpMyAdmin:

```bash
composer setup
```

which runs `composer install`, copies `.env`, `key:generate`,
`migrate --seed --force`, and `storage:link`.

**You still need a database for it to connect to.** Create an empty
`civilwatch` database in phpMyAdmin first (SQL tab: `CREATE DATABASE
civilwatch;`). This path builds the schema from migrations and seeds it —
you get the admin account, offices and announcements, but **not** the sample
reports the SQL import provides.

Running `composer setup` *after* a SQL import is safe: every seeder uses
`firstOrCreate`, and the imported `migrations` table already records all 12
migrations, so nothing runs twice.

### Node is separate now

```bash
composer build    # npm install && npm run build
```

Only needed if you edit `resources/views/welcome.blade.php`.

---

## Android with your menu

Nothing changes on Android. Your Termux menu launcher
(`~/bin/termux-help-menu` → **CIVILWATCH · START WEB**) already runs:

```bash
cd "$HOME/Prd/CIVILWATCH/prc/laravel" && php artisan serve --host=127.0.0.1 --port=8000
```

then waits for port 8000 and opens Brave at `http://127.0.0.1:8000`.

The two machines are independent — each has its own database. Code moves
between them through GitHub; data does not.

---

## Admin login

| Role | Email | Password |
|---|---|---|
| Super Admin | `admin@civilwatch.ph` | `<your-admin-password>` |
| CEO | `ceo@civilwatch.ph` | `<your-ceo-password>` |

Only **super_admin** can write. CEO/CENRO can read every admin page but all
mutation endpoints return `403 Super administrator access is required.`

Dashboard → Reports lets you validate, assign and reject. Rejecting requires
a reason (the API answers `422` without one) and sets `is_public = 0`, which
removes the report from the public community feed.

---

## Citizen registration and report submission

No seed data needed — registration is self-service.

1. Open the app and register with a mobile number and a 6-digit PIN
   (minimum two-part full name, choose a barangay).
2. Sign in with the same number and PIN.
3. Submit a report: category, title, description, barangay, severity.
4. It appears in **My Reports** with a status badge, and in the admin
   dashboard once validated.

API, if you want to test with curl from another terminal:

```bash
# register
curl -s -X POST http://127.0.0.1:8000/api/mobile/auth/register \
  -H 'Content-Type: application/json' -H 'Accept: application/json' \
  -d '{"fullName":"Juan Dela Cruz","phone":"+639171234567","barangay":"San Jose","pin":"123456"}'

# log in
curl -s -X POST http://127.0.0.1:8000/api/mobile/auth/login \
  -H 'Content-Type: application/json' -H 'Accept: application/json' \
  -d '{"phone":"+639171234567","pin":"123456"}'
```

---

## SMS (UniSMS) — OTP delivery (task 1)

The OTP flow sends real SMS through **UniSMS** (<https://unismsapi.com/docs/sms>)
via `app/Services/UniSmsService.php` — plain REST + Basic auth, no Composer
dependency (Laravel `Http` facade).

1. Register a **free** account: <https://unismsapi.com/register>.
2. Copy your **API secret key** (<https://unismsapi.com/api_keys>) and your
   **test Sender ID** (dashboard; new accounts get a random one for testing).
3. Fill them in `.env` (gitignored) and restart `php artisan serve`:

   ```dotenv
   UNISMS_SECRET_KEY=sk_...
   UNISMS_SENDER_ID=YOUR_TEST_SID
   UNISMS_BASE_URL=https://unismsapi.com/api
   ```

Behaviour of `POST /api/mobile/auth/send-otp`:

- **No key (default):** old dev behaviour — the OTP is echoed in the JSON
  *while `APP_DEBUG=true`*, with `sms_sent:false` and an `sms_error` explaining
  why. Production (`APP_DEBUG=false`) answers `503` instead of pretending.
- **Key set:** every request sends `CivilWatch: your verification code is ...`
  (valid 5 minutes). Production responses never include the code; a failed send
  answers `502` with `sms_error` details, and 401/422/429 are logged via
  `Log::warning`.

Test from the command line (curl, same style as above):

```bash
# credit balance (GET /account)
curl -s https://unismsapi.com/api/account -u "$UNISMS_SECRET_KEY:"

# send one test SMS
curl -s -X POST https://unismsapi.com/api/sms -u "$UNISMS_SECRET_KEY:" \
  -H 'Content-Type: application/json' \
  -d '{"recipient":"+639171234567","content":"Hello from CivilWatch","sender_id":"YOUR_TEST_SID"}'
```

Caveats: the **test Sender ID cannot reach Smart/TNT/Sun** numbers (register a
real one at `/sender_ids/new` for deployment), messages cost ₱0.50/SMS at the
lowest top-up tier (1 credit per 160-char segment), and status webhooks need a
public HTTPS URL (not covered here — poll `GET /sms/:reference_id` instead).

---

## Run the E2E tests (Playwright) — required

Playwright drives the real pages so we can **see what actually runs** before
anyone loads the app by hand. It is a required part of running CivilWatch; see
[`../../IMPORTANT.md`](../../IMPORTANT.md) for why.

On the PC, from the repo root, double-click **`RUN_TESTS.bat`**. Or by hand:

```bash
cd e2e
npm install
npx playwright install chromium
npx playwright test
```

The config points at `http://127.0.0.1:8000` and starts
`php artisan serve` itself if it is not already running, so you can run the
suite with or without the backend already up. On the PC, XAMPP ships PHP but
does not always put it on `PATH`; `RUN_TESTS.bat` sets
`PHP_BIN=C:\xampp\php\php.exe` for you when it finds it.

When a test fails, open the report and the trace:

```bash
npx playwright show-report
npx playwright show-trace test-results/<test>/trace.zip
```

**Playwright does not run on Android/Termux** — there is no browser binary for
it. Run it on the PC.

---

## Flutter on the PC

The base URL is chosen at build time with `--dart-define`; the default is
`http://127.0.0.1:8000/api`, which is exactly right when the backend runs on
the same machine.

```bash
cd civ-main
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Other targets:

```bash
# Android emulator (host loopback)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

# Real device on the same WiFi — backend must be on --host=0.0.0.0
flutter run --dart-define=API_BASE_URL=http://<pc-lan-ip>:8000/api
```

---

## Troubleshooting

**`could not find driver` / SQLSTATE connection refused**
MySQL is not running, or `.env` still says `DB_CONNECTION=sqlite`. Start
MySQL in XAMPP and confirm the five `DB_*` lines.

**Access denied for user 'root'@'localhost'**
XAMPP's default root password is empty. If you set one, put it in
`DB_PASSWORD`.

**Import fails on `civilwatch` already existing**
Use the phpMyAdmin **Drop** on the old database first, or run the import
with "Ignore errors" unchecked — the dump uses `CREATE DATABASE IF NOT
EXISTS` and `DROP TABLE IF EXISTS`, so re-importing over itself is safe.

**`/admin/login` returns 500 or a blank page**
The `sessions` table is missing — run `php artisan migrate`. The HTML/JS
dashboard at `/` keeps working, so this is easy to miss. See "Then create the
`sessions` table" above.

**Uploaded report photos return 404**
`php artisan storage:link` was not run. `composer setup` now does it.
On Windows, creating symlinks needs Administrator or Developer Mode; if it
fails, either run a terminal as Administrator or skip photo uploads.

**`SQLSTATE[HY000] [1045] Access denied` after `composer setup`**
`composer setup` connects to a database before you create it. Create an
empty `civilwatch` database first, or import `civilwatch_FINAL.sql` and skip
`composer setup` entirely.

**Port 8000 already in use**
```bash
php artisan serve --host=127.0.0.1 --port=8080
```
Remember to change `API_BASE_URL` to match if you use Flutter.

**A rejected report is still visible on the public map**
The status must be exactly `Rejected`; the row's `is_public` must be `0`.
Both are set together by the reject endpoint.

---

## Not verified

This guide was written inside Termux on Android. The following were **not**
executed on a real Windows PC and are documented from verified local
equivalents rather than from a PC run:

- the phpMyAdmin click-path (the dump itself **was** imported into a scratch
  database and checked — 15 tables, `Rejected` in the ENUM, row counts
  matching the live database)
- `flutter run` (no Flutter SDK on this machine)
- `composer build` / `npm run build` (no Node build performed; only confirmed
  that no served view references `@vite`)
- running under XAMPP Apache as a vhost (not part of this setup — Laravel's
  built-in server is used instead)
- the Playwright E2E suite in `e2e/` (browser tests need a PC; they could not
  be executed from Termux/Android)
