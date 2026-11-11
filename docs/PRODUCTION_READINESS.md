# CIVILWATCH — Production Readiness Checklist

> **Status: not production-ready.** Created 2026-11-11 from a source review of
> the API layer, schema, auth, storage config and the Flutter client.
>
> Everything here was found by **reading code**, not by testing a running
> system: this workspace had no `.env`, no `vendor/`, no database and no Flutter
> SDK. Each item therefore lists the evidence and the check that would prove it
> fixed. Do not tick a box until you have actually run that check.

Scope: security and data privacy gaps. Report-workflow features and UI polish
are deliberately out of scope.

**How to read the priority column**

| Level | Meaning |
|---|---|
| **P0** | Actively exploitable or unlawful. Block any public deployment. |
| **P1** | Serious weakness or data-integrity bug. Fix before a pilot with real citizens. |
| **P2** | Hardening and compliance debt. Schedule before city-wide rollout. |

---

## 1. P0 — Blockers

### SEC-01 · No rate limiting on authentication
**Evidence:** `grep -rn "throttle\|RateLimiter" routes/ app/ bootstrap/` returns
nothing. `routes/api.php` registers the whole `mobile/auth` group with no
middleware. `MobileAuthController::login()` accepts a `pin` matching
`/^\d{6}$/`.

**Why it matters:** a 6-digit PIN is a 1,000,000-value secret. With no attempt
limit, the login endpoint is offline-bruteforceable in minutes regardless of
bcrypt cost. `send-otp` is equally unprotected and spends real money per call
(UniSMS credits).

- [ ] `throttle` on `POST /api/mobile/auth/login` — e.g. 5 attempts / minute / IP+phone
- [ ] `throttle` on `POST /api/mobile/auth/send-otp` — e.g. 3 / 10 min / phone, plus a daily cap
- [ ] `throttle` on `verify-otp`, `verify-reset-otp`, `reset-pin`
- [ ] Throttle the staff endpoints `POST /api/login` and `POST /admin/login`
- [ ] Confirm a lockout response is `429` with `Retry-After` (not a generic 500)

**Proof:** run the login request 20 times in a loop and record the status codes;
expect 401s then 429s.

### SEC-02 · Development pages are publicly served
**Evidence:** `routes/web.php` ends with a catch-all that serves **any** `.html`
under `public/` with no auth. Present today: `test.html` (live OTP harness that
calls `send-otp`), `register-demo.html`, `reset-demo.html`, plus
`dashboard.html`, `users.html`, `analytics.html`, `offices/*`.

**Why it matters:** `test.html` is a free OTP+SMS generator for anyone who finds
the URL, and the demo pages expose internals that no production system should
serve.

- [ ] Delete `public/test.html`, `public/register-demo.html`, `public/reset-demo.html`
- [ ] Decide the fate of the remaining `public/*.html` admin pages (see SEC-03)
- [ ] Remove or restrict the `{any}` catch-all if it is only there for the prototype

**Proof:** after deletion, `curl -o /dev/null -w '%{http_code}'` each path against
the deployed origin; expect 404.

### SEC-03 · The HTML admin UI authenticates in the browser only
**Evidence:** `public/js/app.js:153` `requireAuth()` reads `cw_token` and
`cw_role` from `localStorage`; `getRole()` returns
`localStorage.getItem('cw_role') || 'super_admin'`.

**Why it matters:** anyone can set `cw_role=super_admin` in devtools and the UI
will render the super-admin experience. The API still rejects the calls without
a valid token, so this leaks screens and endpoint shapes — not rows — but it is
not an access control.

- [ ] Either put `public/*.html` behind server-side auth (`auth` + role
      middleware, as `/admin/*` already does), or retire the prototype in favour
      of the Blade admin
- [ ] Never treat client-side `cw_role` as an authorization decision

**Proof:** clear localStorage, set `cw_role=super_admin` by hand, load
`/dashboard.html` — it must not render admin data.

### SEC-04 · Report photos are world-readable
**Evidence:** `MobileReportController::store()` →
`$request->file('photo')->store('report-photos', 'public')` then
`Storage::disk('public')->url($path)`. `config/filesystems.php` gives that disk
`visibility => 'public'` and a plain `/storage` URL. No signed URLs, no expiry,
no auth on the path.

**Why it matters:** citizen photos of dumping sites routinely contain faces,
plate numbers and house fronts, and the row also stores exact `lat`/`lng`.
Random filenames are the only protection.

- [ ] Move uploads to a **private** disk (`local` root or a private S3/MinIO bucket)
- [ ] Store the **relative path** in `photo_url`, build the URL at read time
- [ ] Serve images through short-lived signed URLs or an authenticated controller
- [ ] Verify `laravel/.gitignore` still excludes `/public/storage`

**Proof:** request an image URL logged out; expect 403/404, not the bytes.

### SEC-05 · `APP_DEBUG` leaks OTP codes and stack traces
**Evidence:** `MobileAuthController::sendOtp()` adds `$data['otp'] = $code`
when `config('app.debug')`. `.env.example` ships `APP_DEBUG=true` and
`LOG_LEVEL=debug`.

- [ ] `APP_DEBUG=false` and `LOG_LEVEL=warning` (or `error`) in production
- [ ] Confirm the `send-otp` response body contains no `otp` key
- [ ] Confirm error responses return JSON without trace or query text

**Proof:** unauthenticated invalid request in production; inspect the body.

### SEC-06 · CORS allows every origin
**Evidence:** `config/cors.php` → `'allowed_origins' => ['*']`.

- [ ] Replace `*` with the real admin origin(s) and the Flutter app origins
- [ ] Keep `supports_credentials => false` unless you switch to cookie auth
- [ ] Re-test that the Flutter app and admin panel still work from their real hosts

### PRV-01 · Real credentials are committed in the docs
**Evidence:** `docs/PROJECT_CONTEXT.md` §5 lists the super-admin password, the
CEO password and a citizen PIN in plain text.

- [ ] Rotate every credential that appears in the repo (they are in git history)
- [ ] Replace the table with placeholders and a pointer to the password manager
- [ ] Grep the whole tree for `@civilwatch.ph` and `Admin@2026` before publishing

**Note:** rotating is required because editing the file does not remove the value
from history.

---

## 2. P1 — Fix before real citizen data

### DATA-01 · Reference numbers collide
**Evidence:** `CitizenReport::generateReferenceNumber()` →
`static::whereYear('created_at', $year)->count() + 1`, with a `unique` index on
`reference_number`.

**Why it matters:** two simultaneous submissions compute the same number and the
second insert throws a 500. Deleting a report also makes the next insert
collide. Sequence numbers are also guessable, exposing total report volume.

- [ ] Generate from a DB sequence / `AUTO_INCREMENT`-backed counter, or
      `SELECT ... FOR UPDATE` inside a transaction
- [ ] Add a test that submits N reports concurrently and asserts N unique numbers

### DATA-02 · Report creation is not transactional
**Evidence:** `MobileReportController::store()` inserts the report, then
`ReportActivity::create()`, then `transitionTo()` (update + activity +
notification) with no surrounding transaction. `transitionTo()` itself writes to
three tables.

- [ ] Wrap submission in `DB::transaction()`
- [ ] Wrap `transitionTo()` writes so a notification failure cannot leave a
      status with no activity row (or activity with no notification)
- [ ] Verify by forcing an exception mid-flow and confirming no partial row

### DATA-03 · No automated tests
**Evidence:** only `tests/Unit/ExampleTest.php` and
`tests/Feature/ExampleTest.php` — Laravel scaffolding.

- [ ] Feature tests for: citizen register → login → submit → admin validate →
      assign → status change
- [ ] Feature test for the 403 path (CEO touching another office's report)
- [ ] Feature test for rejection without a reason → 422
- [ ] Test that a citizen cannot read another citizen's report

### OPS-01 · Fresh import breaks `/admin/login`
**Evidence:** `laravel/.env.example` sets `SESSION_DRIVER=database`, but
`civilwatch_FINAL.sql` contains **no `sessions` table**
(`grep -c 'CREATE TABLE `sessions`' civilwatch_FINAL.sql` → `0`).

- [ ] Make `composer setup` the only documented path, or add `sessions` to the dump
- [ ] Confirm `php artisan migrate` runs after any phpMyAdmin import
- [ ] Add the failure to `laravel/docs/SETUP_PC.md` if it is not already there

### PRV-02 · Uploaded images are stored exactly as received
**Evidence:** `'photo' => 'nullable|image|max:5120'` is the only control.

- [ ] Re-encode server-side (strips payloads and normalises format)
- [ ] Strip EXIF — phone photos carry GPS coordinates and device identifiers
- [ ] Cap pixel dimensions (decompression bombs pass a 5 MB check)
- [ ] Add malware scanning or at minimum serve from a non-executable location
- [ ] Record file hash + uploader for chain of custody

### PRV-03 · Precise location plus identity
**Evidence:** `citizen_reports` stores `lat`/`lng` as `decimal(10,7)` joined to
`citizen_id`, and `citizen` name/phone are returned in
`CitizenReport::toApiArray()` for admin panels.

- [ ] Decide whether the public/community endpoints need full precision or a
      fuzzed point (7 decimals ≈ 1 cm)
- [ ] Confirm the community endpoint never returns reporter identity — it
      currently returns `imageUrl` and exact coordinates for approved reports
- [ ] Document the decision; it is a policy choice, not a bug

### PRV-04 · No erasure or export path
**Evidence:** no delete/export endpoints exist for citizens; `citizens` rows
cascade-delete reports via FK, but nothing exposes that to a data subject.

- [ ] Decide the process for an access request (export a citizen's reports)
- [ ] Decide the process for erasure vs. lawful retention of government records
- [ ] Document both in the privacy notice

### SEC-07 · Tokens are long-lived and over-broad
**Evidence:** `login()` calls `$citizen->tokens()->delete()` before issuing a new
token — logging in on a second device silently signs out the first.
`verifyOtp()` issues a token without revoking older ones. No expiry is set on
the token path; Sanctum ships `expiration` as `null`.

- [ ] Set a token expiration in `config/sanctum.php`
- [ ] Stop revoking all tokens on login, or make the behaviour intentional and documented
- [ ] Revoke tokens on PIN reset (already done) and on account deactivation
- [ ] Confirm `is_active` is checked on every authenticated request, not only login

### SEC-08 · Unverified: OTP attempt limits
**Evidence:** OTP validity lives in `OtpCode::findValid()` / `OtpCode::issue()`
(`app/Models/OtpCode.php`) — the model was **not** reviewed here.

- [ ] Confirm there is a per-code attempt counter and a hard lockout
- [ ] Confirm codes expire (the SMS text says 5 minutes — verify the code agrees)
- [ ] Confirm `issue()` invalidates previous unused codes
- [ ] Confirm `verify-reset-otp` does not consume, and `reset-pin` does (by design)

### SEC-09 · Unverified: HTML escaping in the admin pages
**Evidence:** report `description`, `concern` and rejection reasons are free text
written by citizens and admins, and are rendered by `public/js/*` and the Blade
views. Escaping was not audited.

- [ ] Audit every template that interpolates report/citizen/announcement text
- [ ] Ensure `innerHTML` is fed escaped content or text nodes only
- [ ] Test by submitting `<img src=x onerror=alert(1)>` as a concern and as a rejection reason

### SEC-10 · Unbounded community response
**Evidence:** `MobileReportController::community()` ends in `->get()` with no
pagination; the admin index does cap `per_page` at 500.

- [ ] Paginate or geo-bound the community map endpoint
- [ ] Add an index on `(is_public, status)` if the table will grow

---

## 3. P2 — Compliance and hardening

### PRV-05 · Philippines Data Privacy Act (RA 10173) obligations
Not legal advice — confirm with the city's DPO. At minimum a government system
holding citizen identity, contact details, location and photographs needs:

- [ ] A privacy notice shown before registration (the app collects a Terms &
      Privacy tick — verify the text is real, not a placeholder)
- [ ] A documented lawful basis and purpose limitation
- [ ] A retention and disposal schedule per record type (reports, photos, OTPs,
      tokens, logs)
- [ ] A breach response procedure with NPC notification timelines
- [ ] A data processing agreement for every processor (UniSMS for phone numbers
      and OTP message content; the hosting provider)
- [ ] Confirmation of where data is stored and whether any cross-border transfer
      occurs
- [ ] A Data Protection Impact Assessment if the system is registered with the NPC

### PRV-06 · Audit trail
- [ ] Log who viewed or downloaded a report photo, and when
- [ ] Keep admin status changes attributable to a user id (currently activity rows
      record the transition, not always the actor)
- [ ] Make audit logs append-only and set a retention period

### PRV-07 · Data minimisation
- [ ] `INTEGRATION_CONTEXT.md` says email is collected at registration but not
      persisted — confirm whether it is now stored, and stop collecting it if it
      is unused
- [ ] Confirm OTP codes and PINs never appear in logs
- [ ] Drop debug logging of request payloads before production

### OPS-02 · Transport and headers
- [ ] HTTPS only; `APP_URL` set to the real `https://` origin
- [ ] HSTS, `X-Content-Type-Options`, `X-Frame-Options`/`frame-ancestors`, and a
      Content-Security-Policy on the admin pages
- [ ] `APP_ENV=production`, `APP_KEY` set, config cached
      (`php artisan config:cache`)

### OPS-03 · Backups and recovery
- [ ] Automated database backups on a schedule, stored off the app server
- [ ] Photo storage backed up separately from the database
- [ ] A **restore drill** actually performed and timed
- [ ] Documented RPO/RTO

### OPS-04 · Runtime
- [ ] Queue worker running under a supervisor if notifications move to a queue
      (`QUEUE_CONNECTION=database` is already set)
- [ ] `php artisan storage:link` run on deploy
- [ ] PHP upload limits consistent with the 5 MB rule
- [ ] Error tracking and uptime monitoring, with alerting that reaches a person
- [ ] Dependency audit (`composer audit`, `flutter pub outdated`) and a patch cadence

### OPS-05 · Two admin UIs
- [ ] Decide: keep both, or retire `public/*.html` after parity
- [ ] Whichever survives, make it the one with server-side auth

---

## 4. Definition of done

A deployment is production-ready only when **all** of the following are true:

1. Every P0 item is ticked and its proof command has been run against the
   deployed origin — not localhost.
2. No credential that has ever been committed is still valid.
3. A real citizen photo is **not** retrievable without authorization.
4. Login returns `429` after repeated wrong PINs.
5. `/test.html`, `/register-demo.html` and `/reset-demo.html` return 404.
6. The database has been restored from backup at least once, successfully.
7. The privacy notice is live and names the retention periods.

## 5. Things deliberately not fixed here

These were observed and left alone because they are product decisions, not bugs:

- `README`/docs mention a `staff` role that does not exist; the dashboard
  "Staff" stat is always 0.
- CEO/CENRO pages make no API calls (static shells) — by current design.
- The parent `SerenoLawrence/CIVILWATCH` repo is stale and out of scope.
- No Flutter test suite; Dart is still verified statically only.
