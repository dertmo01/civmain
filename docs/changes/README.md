# CIVILWATCH — Change Log

One markdown file per change. Newest last. Every code change made by the
`changelog` skill lands here with its commit hash.

| # | Date | Commit | Change |
|---|---|---|---|
| 001 | 2026-10-04 | `c1e9035` | [Initial backup — civ-main + laravel](2026-10-04-001-initial-backup.md) |
| 002 | 2026-10-06 | `ddbf5be` | [Graphify knowledge graph + opencode integration](2026-10-06-002-graphify-setup.md) |
| 003 | 2026-10-06 | `c0669de` | [iOS permissions, ATS exception, bundle id](2026-10-06-003-ios-permissions.md) |
| 004 | 2026-10-06 | `a16f8c1` | [API base URL + remove demo Advance Status button](2026-10-06-004-api-base-url-demo-button.md) |
| 005 | 2026-10-06 | `71df2c2` | [Android branding, camera permission, cleartext](2026-10-06-005-android-branding.md) |
| 006 | 2026-10-06 | `fc497bd` | [401 JSON on API + DB session timezone](2026-10-06-006-401-json-db-timezone.md) |
| 007 | 2026-10-06 | `5db5ba6` | [Docs: stop claiming the app has no backend](2026-10-06-007-docs-backend-truth.md) |
| 008 | 2026-10-06 | `98e02f5` | [Submitted/approved reports invisible until restart](2026-10-06-008-report-visibility.md) |
| 009 | 2026-10-06 | `04c3fba` | [Reject a report with a reason, end to end](2026-10-06-009-reject-with-reason.md) |
| 010 | 2026-10-06 | `03aa975` | [Repair the dead analytics, notification and user-list endpoints](2026-10-06-010-repair-dead-admin-endpoints.md) |
| 011 | 2026-10-06 | `3e21b70` | [Drop the legacy /api/reports subsystem](2026-10-06-011-drop-legacy-reports-code.md) |
| 012 | 2026-10-06 | `9bfeab2` | [Gate every admin write behind super_admin](2026-10-06-012-super-admin-write-gate.md) |
| 013 | 2026-10-06 | `2e58906` | [Super admin reference, DEVLOG cross-links, graph refresh](2026-10-06-013-super-admin-reference-graph.md) |
| 014 | 2026-10-07 | `cdac1cb` | [One-file XAMPP database import and PC setup guide](2026-10-07-014-xampp-database-import-setup.md) |
| 015 | 2026-10-07 | `9fdad84` | [Export session context for cross-machine handoff](2026-10-07-015-session-context-export.md) |
| 016 | 2026-10-07 | `994d6ed` | [Refresh Flutter and Composer dependencies for PC setup](2026-10-07-016-pc-dependency-refresh.md) |
| 017 | 2026-10-07 | `297a78b` | [Auto-update run scripts for app and backend](2026-10-07-017-auto-update-run-scripts.md) |
| 018 | 2026-10-07 | `cccc83c` | [Add the missing sessions migration so web pages stop 500ing](2026-10-07-018-missing-sessions-migration.md) |
| 019 | 2026-10-07 | `1c08c6e` | [RUN_APP: run on Chrome and auto-start the backend](2026-10-07-019-run-app-chrome-and-backend.md) |
| 020 | 2026-10-07 | `40b619b` | [Report photos: missing storage link and CORS header](2026-10-07-020-report-photo-storage-link-and-cors.md) |
| 021 | 2026-10-07 | `dcc171c` | [PC health-check scripts (Windows + Termux) and companion repo](2026-10-07-021-pc-health-check-scripts.md) |
| 022 | 2026-10-07 | `dc8c30c` | [What `git pull` gives you on the PC vs what you must install](2026-10-07-022-pull-vs-install-on-pc.md) |
| 023 | 2026-10-07 | `e95e9ea` | [PC setup: the SQL import path never ran the `sessions` migration](2026-10-07-023-sessions-migration-in-pc-setup.md) |
| 024 | 2026-10-08 | `857a723` | [Pull the PC companion repo: civilwatch_check_pc into civmain](2026-10-08-024-pull-civilwatch-check-pc.md) |

## Template

New files follow `docs/changes/TEMPLATE.md`. The `changelog` skill writes them
automatically after each change.

| 025 | 2026-10-08 | `HEAD` | [QA: GIS status/palette + map scope](2026-10-08-025-qa-gis-status-palette-and-map-scope.md) |
| 026 | 2026-10-08 | `HEAD` | [QA: category naming + filter integrity](2026-10-08-026-category-naming-and-filter-integrity.md) |
| 027 | 2026-10-08 | `HEAD` | [QA: date filter search + dynamic range labels](2026-10-08-027-date-filter-search-and-dynamic-range-labels.md) |
| 028 | 2026-10-08 | `HEAD` | [QA: login creds + users table from API](2026-10-08-028-login-creds-and-users-table-from-api.md) |
| 029 | 2026-10-08 | `HEAD` | [QA: polish + cleanup + docs](2026-10-08-029-polish-cleanup-docs.md) |
| 030 | 2026-10-08 | `1f9c078` | [Unauthenticated admin pages returned 500 instead of redirecting to login](2026-10-08-030-guest-redirect-admin-login.md) |
| 031 | 2026-10-08 | `05b8e67` | [One-click boot script: START_ALL.bat starts the whole PC stack](2026-10-08-031-start-all-boot-script.md) |
| 032 | 2026-10-08 | `89d9eaf` | [Persist an Approved status so approve/assign/map/monitoring/Android agree](2026-10-08-032-approved-status-flow-fix.md) |
| 033 | 2026-10-09 | `fa9a49f` | [graphify now runs on the PC — graph refreshed with SQL + PHP folded in](2026-10-09-033-graphify-on-pc.md) |
| 033 | 2026-10-13 | `91086ee` | [Require Playwright E2E: scaffold, run script and docs](2026-10-13-033-playwright-required.md) |
| 034 | 2026-10-13 | `e61e0bc` | [Record UniSMS as the planned primary SMS provider](2026-10-13-034-unisms-sms-task.md) |
| 035 | 2026-10-14 | `6e5704d` | [Office list restricted to CEO and CENRO](2026-10-14-035-office-list-ceo-cenro.md) |
| 036 | 2026-10-14 | `6e5704d` | [Assign-office: real Date Submitted, readable recommendation, responsive layout](2026-10-14-036-assign-office-date-and-form.md) |
| 037 | 2026-10-14 | `6e5704d` | [Approved reports leave Pending Reports](2026-10-14-037-approved-leaves-pending.md) |
| 038 | 2026-10-14 | `6e5704d` | [Remove Playwright E2E](2026-10-14-038-remove-playwright.md) |
| 039 | 2026-10-15 | `HEAD` | [Graph-first retrieval rules + in-repo Obsidian/ICM memory structure](2026-10-15-039-graph-first-retrieval-and-icm-memory.md) |
| 040 | 2026-10-15 | `HEAD` | [GIS map emoji marker replaced with a proper category icon](2026-10-15-040-gis-map-emoji-marker-to-icon.md) |
| 041 | 2026-10-15 | `HEAD` | [Clean up Assign Report modal and restrict priority to the assigned office](2026-10-15-041-assign-report-cleanup-priority-permissions.md) |
| 042 | 2026-10-15 | `HEAD` | [Monitoring report view reused pending-reports detail layout with corrected navigation, dates, and photo placeholder](2026-10-15-042-monitoring-report-details-reuse.md) |
| 043 | 2026-10-15 | `HEAD` | [Fix report view link JavaScript quoting](2026-10-15-043-report-view-link-javascript-quoting.md) |
| 044 | 2026-10-15 | `HEAD` | [Report details redesigned to two-column workflow layout](2026-10-15-044-report-details-redesign.md) |
| 045 | 2026-10-15 | `HEAD` | [Embedded report detail panel in Monitoring page](2026-10-15-045-monitoring-embedded-report-detail.md) |
| 046 | 2026-10-15 | `HEAD` | [Dedicated Monitoring report details page](2026-10-15-046-monitoring-dedicated-report-detail-page.md) |
| 047 | 2026-10-15 | `HEAD` | [Reporter details panel in admin report views + Home Barangay fix](2026-10-15-047-reporter-details-and-home-barangay.md) |
| 048 | 2026-10-15 | `HEAD` | [Citizen registration now captures a full home address](2026-10-15-048-registration-full-address.md) |
| 049 | 2026-10-15 | `HEAD` | [Unify the Digos City barangay list to the official 26 everywhere](2026-10-15-049-unify-digos-barangay-list.md) |
| 050 | 2026-10-15 | `HEAD` | [Session start: fresh sessions continue from a short handoff, existing sessions keep their history](2026-10-15-050-session-start-handoff.md) |
| 051 | 2026-10-15 | `HEAD` | [Token-lean session start: read `## NOW` + the last 3 changelog rows, with research fallbacks](2026-10-15-051-token-lean-handoff-now-block.md) |
| 052 | 2026-10-15 | `HEAD` | [CEO/CENRO report details load from the API; reporter panels show name, address and phone](2026-10-15-052-office-report-details-live-api-reporter-panels.md) |
| 053 | 2026-10-16 | `HEAD` | [CEO/CENRO list pages load from the API; offices can post status updates](2026-10-16-053-office-list-pages-live-and-status-post.md) |
| 054 | 2026-10-16 | `b9c9bfe` | [Dark mode on/off toggle in Profile (and fix the missing dark theme body)](2026-10-16-054-dark-mode-toggle-switch.md) |
| 055 | 2026-10-16 | `f8e24a7` | [Animated Sun/Moon dark mode toggle — and a palette that actually switches app-wide](2026-10-16-055-animated-sun-moon-dark-mode-toggle.md) |
| 056 | 2026-10-16 | `20cdf91` | [Unified theme palette as a ThemeExtension — one theme state, Light default](2026-10-16-056-unified-theme-palette-theme-extension.md) |
| 057 | 2026-10-16 | `3040d62` | [Dark Mode hid Home + Notifications text — white cards, brand green, fixed-light map](2026-10-16-057-dark-mode-contrast-home-notifications.md) |
| 058 | 2026-10-16 | `f8d5e03` | [Dark Mode hid the Profile + My Reports icons — same fixed-ink defect, now on shared widgets and the nav bar](2026-10-16-058-dark-mode-ink-profile-reports-widgets.md) |
| 059 | 2026-10-16 | `6a45925` | [Record the pre-login Dark Mode contrast audit as a deferred task](2026-10-16-059-record-pre-login-contrast-task.md) |
| 060 | 2026-10-19 | `54d1ebe` | [Dark Mode hid the whole pre-login flow — same fixed-ink defect as 057/058, now on landing, auth, visitor and track screens](2026-10-19-060-pre-login-dark-mode-ink.md) |
| 061 | 2026-10-19 | `9525085` | [Three Dark Mode status tints sat just under 3:1 — Submitted, Assigned, Approved darkened](2026-10-19-061-status-tint-dark-values.md) |
| 062 | 2026-10-19 | `958ce55` | [Guests were stuck in one theme — Dark Mode toggle added to the visitor banner](2026-10-19-062-guest-dark-mode-toggle.md) |
| 063 | 2026-10-19 | `f45c762` | [The admin Monitoring Report Details page ignored Dark Mode — hardcoded light palette in its inline CSS](2026-10-19-063-admin-monitoring-details-dark.md) |
| 064 | 2026-10-19 | `67216c3` | [Flutter registration returned 500 — `artisan migrate` had been dying on a record-less `sessions` table, so the citizens address columns never existed](2026-10-19-064-register-500-blocked-migrations.md) |
| 065 | 2026-10-19 | `fd5d5a1` | [OTPs were never sent — UniSMS wired in as the primary SMS provider, with an honest no-key fallback](2026-10-19-065-unisms-otp-integration.md) |
| 066 | 2026-10-19 | `0788307` | [No way to test SMS/OTP outside the app — test.html register harness whose Verify step only accepts the OTP this page requested](2026-10-19-066-test-html-bound-otp-verify.md) |
| 067 | 2026-10-21 | `d53f83f` | [Registration skipped the OTP screen — the existing `OtpScreen` was dead code](2026-10-21-067-registration-otp-wired.md) |
| 068 | 2026-10-21 | `d53f83f` | [Registration OTP flow had no visual demo - added an app-style browser walkthrough](2026-10-21-068-registration-visual-demo.md) |
| 069 | 2026-10-21 | `d53f83f` | [Reset PIN had no UI walkthrough - added a mockup that says what is real vs fake](2026-10-21-069-reset-pin-mockup.md) |
| 070 | 2026-10-21 | `d53f83f` | [Reset PIN was a fake - a correct OTP now actually changes the PIN](2026-10-21-070-real-reset-pin.md) |
| 071 | 2026-10-21 | `d53f83f` | [Reset testing needed a real SMS in the app - added a debug-only Mock / Live switch](2026-10-21-071-in-app-mock-live-reset.md) |
| 072 | 2026-10-21 | `ea059a2` | [Mock testing still needed SMS - registration and reset now skip OTP in debug](2026-10-21-072-mock-skips-otp.md) |
| 075 | 2026-11-17 | `(uncommitted)` | [Dashboard charts reverted - dashboard back to stat cards only (undoes 073 and 074)](2026-11-17-075-dashboard-charts-reverted.md) |
| 076 | 2026-11-17 | `(see git log)` | [Critical security fixes - citizen tokens on staff API, stored XSS, published admin password, OTP echo](2026-11-17-076-critical-security-fixes.md) |
