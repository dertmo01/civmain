# 073 — Production readiness checklist from a security and privacy review

**Date:** 2026-11-11
**Commit:** pending backfill (`git log -1 -- docs/PRODUCTION_READINESS.md`)

## Why

The owner asked whether the system is solid, whether it is UI- or
backend-based, whether separate databases are possible, and whether image
storage is viable for a government system. Answering that required reading the
API, schema, auth, storage config and Flutter client. The findings were worth
keeping rather than losing in a chat, so they are now a tracked checklist.

## What was added

- `docs/PRODUCTION_READINESS.md` — 25 tracked items across 86 checkboxes in
  three tiers (P0 blockers, P1 pre-pilot, P2 compliance/hardening), each with
  the source evidence, the reason it matters, the actions, and the check that
  proves it fixed.
- A "Definition of done" section and an explicit "not fixed here" list so the
  doc does not silently expand into a rewrite.
- This changelog entry and the index row.
- `docs/SESSION_CONTEXT.md` `## NOW`: `at:` bumped and `blocked:` now points at
  the checklist instead of naming only the dev pages.

## Root cause

There was no single place recording what stands between this prototype and a
production deployment. The security posture was visible only by reading
`routes/api.php`, `MobileReportController`, `config/cors.php` and
`public/js/app.js` together.

## Findings recorded (no code changed)

Highest severity, all confirmed by source inspection:

1. **No rate limiting anywhere** — `throttle`/`RateLimiter` do not appear in
   `routes/`, `app/` or `bootstrap/`; a 6-digit PIN login is bruteforceable and
   `send-otp` spends real SMS credits.
2. **`public/*.html` served unauthenticated by a catch-all** in
   `routes/web.php`, including `test.html`, an OTP harness.
3. **HTML admin auth is client-side** — `requireAuth()` trusts
   `localStorage.cw_role`.
4. **Photos on the `public` disk** with permanent unsigned URLs.
5. **`APP_DEBUG=true` echoes OTP codes** in `.env.example`.
6. **CORS `allowed_origins => ['*']`**.
7. **Live credentials committed** in `docs/PROJECT_CONTEXT.md` §5.
8. **Reference numbers collide** — `count() + 1` against a `unique` index.
9. **Report creation is not transactional** across three tables.
10. **No test suite** beyond Laravel's scaffolding.

## Verification

- Reviewed: `laravel/routes/api.php`, `routes/web.php`, `config/cors.php`,
  `config/filesystems.php`, `config/database.php`, `config/auth.php`,
  `bootstrap/app.php`, `MobileAuthController`, `MobileReportController`,
  `AdminCitizenReportController`, `CitizenReport`, `pubspec.yaml`,
  `report_service.dart`, `public/js/app.js`, migrations, `.env.example`,
  `composer.json`.
- `grep -rn "throttle\|RateLimiter" routes/ app/ bootstrap/` → no matches.
- `grep -c 'CREATE TABLE `sessions`' laravel/civilwatch_FINAL.sql` → `0`.
- `ls tests/**/*.php` → `ExampleTest.php` only.

**Not run:** the application, a database, `php artisan test` and any Flutter
build. This workspace has no `.env`, no `vendor/`, no MySQL and no Flutter SDK,
so every item in the checklist is a source-level finding awaiting a real check.
No item should be treated as verified until its proof command has been run.

**Not run:** `graphify update .` — graphify is not installed in this
environment (`graphify: command not found`).

## Push

Not pushed. This clone has a single remote named `origin`
(`dertmo01/civmain`); the `backup` remote that `AGENTS.md` documents does not
exist here, so the documented `git push backup main` and the
`git ls-remote backup main` verification could not be performed.
