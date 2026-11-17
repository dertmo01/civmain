# Critical security fixes: citizen tokens on staff API, stored XSS, published admin password, OTP echo

- **Date:** 2026-11-17
- **Commit:** `(see git log)`
- **Type:** fix (security)
- **Areas:** Laravel (auth config, routes, middleware, mobile auth, seeder, SQL dump), admin web panel (all report pages, office pages, shared JS), docs

## Problem

A full audit found four Critical issues.

1. **C1: citizen tokens worked on staff routes.** A citizen's mobile Sanctum token was accepted on every `auth:sanctum` staff route. With it, any citizen (and, through the open register endpoint, anyone) could read every report, including the reporters' names, phones and addresses, plus the staff list and analytics. They could also delete all citizen notifications.
2. **C2: stored XSS in the admin panel.** Citizen-controlled text was inserted unescaped through `innerHTML` and Leaflet popups across the panel: report concern and description, citizen name, phone and address, barangay, notification text, and the `?ref=` URL parameter. The staff bearer token lives in `localStorage` and never expires, so one malicious report could take over the super-admin account.
3. **C3: super-admin password published.** The password was shown on the login page and auto-filled into the form. It was also printed by the seeder, written in plain text in `civilwatch_FINAL.sql`, and repeated in several docs.
4. **C4: OTP returned to the caller.** `send-otp` returned the OTP code in its response whenever `APP_DEBUG=true`, which is the `.env.example` default. Anyone could then take over an account through `reset-pin` or `verify-otp`.

## Cause

1. `config/auth.php` had no `sanctum` guard entry. Sanctum then runs with `provider = null` and accepts a token from any tokenable model. `EnsureSuperAdmin` passes all GETs, and the office filter only applies to the `ceo`/`cenro` roles.
2. The pages built their HTML with template strings and had no escaping helper.
3. Demo-convenience credentials were left in production paths.
4. The dev-autofill OTP echo was gated on `app.debug` alone.

## Changes

| File | Change |
|---|---|
| `laravel/config/auth.php` | Added `'sanctum' => ['driver' => 'sanctum', 'provider' => 'users']`. |
| `laravel/app/Http/Middleware/EnsureStaff.php` | **New.** Returns 403 unless `$request->user()` is an `App\Models\User` (defence in depth). |
| `laravel/bootstrap/app.php` | Registered the `staff` alias. |
| `laravel/routes/api.php` | `staff` added after `auth:sanctum` on the `/api/admin/*` group and on the legacy staff group. Mobile routes are unchanged. |
| `laravel/app/Http/Controllers/Mobile/MobileAuthController.php` | The OTP is echoed only when `app()->environment('local') && config('app.debug')`. The two "fail honestly" branches use the same flag. |
| `laravel/.env.example` | Comment warning that a reachable server needs `APP_ENV=production` and `APP_DEBUG=false`. |
| `laravel/public/index.html` | Removed the "Demo credentials" note and the password auto-fill. |
| `laravel/database/seeders/DatabaseSeeder.php` | The admin password comes from `SEED_ADMIN_PASSWORD`, or `Str::password(16)` is generated and printed once on creation. |
| `laravel/civilwatch_FINAL.sql` | Plain-text passwords and PIN removed from the header. It now warns that the seeded passwords are public and must be rotated. The password hashes are unchanged. |
| `START_ALL.bat`, `laravel/README.md`, `laravel/DEVLOG.md`, `docs/PROJECT_CONTEXT.md`, `laravel/docs/SETUP_PC.md`, `laravel/docs/SUPER_ADMIN.md` | Passwords replaced with placeholders. Historical `docs/changes/*` entries were left as written (append-only). |
| `laravel/public/js/utils.js` | New `Utils.esc` (HTML text and attributes), `Utils.jsArg` (JS string literal inside an inline handler) and `Utils.safeUrl` (http(s), `data:image/*` or relative paths only). `statusBadge`/`categoryBadge` fallback labels, `showToast` messages and `highlight` are now escaped. |
| `laravel/public/js/app.js` | Local `appEsc`, applied to the user name, initials and title (sidebar and navbar) and to the notification panel (id, title, message, time). |
| `laravel/public/{pending-reports,resolved-reports,dashboard,monitoring,report-details,monitoring-report-details,assign-office,gis-map,users}.html` | Every data value going into HTML or a popup is escaped. Photo `src` uses `safeUrl`. Inline `onclick` handlers use `jsArg`, which fixes quote break-outs. Hrefs use `encodeURIComponent`. |
| `laravel/public/offices/{ceo,cenro}/{reports,inprogress,resolved,map,report-details}.html` | Same treatment. Fixes an `onclick="location.href='…?ref=${encodeURIComponent(ref)}'"` break-out: `encodeURIComponent` does not encode `'`. |
| `laravel/resources/views/admin/map.blade.php` | Local `esc` used in the Leaflet popup. `@json` is unchanged. |

Pages with no dynamic sinks were not changed: `analytics.html`, `settings.html`, and the office `dashboard`, `analytics` and `settings` pages render only hard-coded arrays. Demo pages (`test.html`, `register-demo.html`, `reset-demo.html`) were not changed either; they should be removed in a separate change.

## Verification

- **JS syntax.** Served `laravel/public` from a throwaway localhost server and compiled every inline `<script>` and every `public/js/*.js` file with `new Function()` in a browser. 36 files were checked. Two errors, both pre-existing and unrelated to this change: `js/auth.js` (dead file, `user ? .name`) and `users.html` (`let usersData` declared twice, a known bug).
- **Helpers against a real payload.** Tested in a browser with `` <img src=x onerror=alert(1)>"'` ``:
  - the payload renders as text, and no `img[onerror]` is created;
  - the title attribute round-trips intact;
  - a `jsArg` handler break-out does not execute;
  - `safeUrl('javascript:…')`, `//evil.com` and `data:text/html` return `''`;
  - a relative photo URL with `&` is preserved;
  - toasts and badges escape the payload.
- **Diff hygiene.** No mojibake in any changed file, and line endings are kept (diff is 316+/245-).
- **Not run:**
  - **PHP lint and Laravel tests.** No PHP on this machine. Run `C:\xampp\php\php.exe -l` on the changed PHP files and `php artisan test`.
  - **Live check of C1.** Log in as a citizen, call `GET /api/admin/citizen-reports` with that token, and expect 403. Staff login and the panel should still work.
  - **Visual check of the admin pages in a browser against a running backend.**

## Follow-up required (manual)

- **Rotate the published passwords** on every database built from the dump or the old seeder: `admin@civilwatch.ph`, `ceo@civilwatch.ph` and citizen `+639171234567`. They remain in git history.
- Set `APP_ENV=production` and `APP_DEBUG=false` on any machine other people can reach.
