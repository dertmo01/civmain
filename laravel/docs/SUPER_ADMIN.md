# Super Admin — Reject with Notes, Pending Queue, Approve Flow

Reference for the two administrator UIs, the report status workflow they drive,
and the `super_admin` role gate. Written for someone opening this repo cold.

Backend commands below assume:

```bash
cd prc/laravel
setsid nohup mariadbd --user=$USER --datadir=$HOME/.local/var/mysql \
  --socket=$HOME/.local/var/mysql/mysql.sock --bind-address=127.0.0.1 \
  --innodb-buffer-pool-size=64M --performance-schema=OFF >/dev/null 2>&1 </dev/null & disown
setsid nohup php -S 127.0.0.1:8000 -t public >./.srv.log 2>&1 </dev/null & disown
```

Services die between shell sessions on Termux — restart them inside the same
command that tests them.

---

## Two admin UIs

There are **two** administrator interfaces and they do not share a line of code.
Both stay. Do not "unify" them without an explicit decision.

| | Prototype HTML | Blade panel |
|---|---|---|
| Entry | `GET /` → `public/index.html` (`routes/web.php:7`) | `GET /admin/login` (`routes/web.php:11`) |
| Auth | **Client side only.** `requireAuth()` at `public/js/app.js:153` checks that `cw_token` exists in `localStorage`. The HTML itself is served with no session check. | Server side — Laravel `auth` + session cookie + CSRF |
| API calls | Bearer token via `Api` helper (`public/js/app.js`) | Server-side `Auth`, no token |
| Pages | 11 super-admin + 16 CEO/CENRO shells (`.html` in `public/`) | 12 Blade views in `resources/views/admin/` |
| Reject report | **Yes** — `report-details.html` | No (validate / assign / status only) |
| Pending queue | **Yes** — `pending-reports.html`, 30s auto-refresh | No |
| Users page | `users.html` | No |

The catch-all at `routes/web.php:38` serves any `public/*.html` with no
server-side auth. That is intentional for the prototype: every real capability
is behind `/api/*`, and since commit `9bfeab2` every **write** on `/api/admin/*`
is refused unless the caller is `super_admin`. Reading an empty shell leaks no
data.

CEO/CENRO pages (`public/offices/ceo/*.html`, `public/offices/cenro/*.html`)
currently make **zero** API calls — they are static shells. Their nav comes from
`app.js:270`/`app.js:300`.

---

## Reject with notes

A super admin can reject a submitted report and must give a reason. The reason
is shown to the citizen and is stored in the report's activity history.

**Where:** `public/report-details.html` → *Reject* → modal with a required
textarea.

**What happens, in order:**

1. `report-details.html:651` POSTs `/api/admin/citizen-reports/{id}/status`
   with `status: 'Rejected'` and `description: <reason>`. An empty reason
   shows `Utils.showToast('Please enter a reason...', 'error')` and does not
   close the modal.
2. `AdminCitizenReportController::updateStatus` (`:128`) validates
   `description` with `required_if:status,Rejected`.
3. `:141` rejects the call with **422** if the report is not in
   `CitizenReport::REJECTABLE_STATUSES` (`Submitted`, `Pending Validation`).
   An assigned or in-progress report cannot be rejected — reassign instead.
4. `CitizenReport::transitionTo` (`:113`) sets `is_public = false`, so the
   report disappears from the public community feed.
5. It writes a `report_activities` row carrying the admin's note, and a
   `citizen_notifications` row whose `message` is
   `"<ref> — Rejected. <reason>"`.

**Where the citizen sees it:** My Reports shows a red `Rejected` badge; the
four tracking screens (`progress_timeline.dart`, `status_update_screen.dart`,
`track_report_screen.dart`, `track_by_reference_screen.dart`) swap the 5-step
timeline for `widgets/timeline/rejection_notice.dart`, which pulls the reason
out of the last `status == 'Rejected'` activity entry.

**Why `statusIndex` is `-1`:** `IncidentReport.statusOrder` is deliberately the
happy path only. Rejected is an exit from the flow, not a step in it, so
`report.dart:45` returns `-1` and the timelines render a rejection instead of
five uncompleted nodes.

---

## Pending queue

`public/pending-reports.html` merges `Submitted` and `Pending Validation` into
one work queue and **auto-refreshes every 30 seconds**. This is the screen the
reject bug was reported from: because `Rejected` was missing from
`STATUS_ORDER`, the prototype's reject action sent `status:'Submitted'`, so the
report reappeared in this queue forever.

The sidebar badge count comes from `GET /api/analytics/summary`
(`app.js:372`), field `pending_validation` (= `Submitted` + `Pending
Validation`).

Blade equivalent: `/admin/citizen-reports` with `?status=...` (the filter
dropdown includes `Rejected`).

---

## Approve flow

Statuses, in order (`CitizenReport::STATUS_ORDER`):

```
Submitted → Pending Validation → Assigned to Office → In Progress → Resolved
                                                        ↘ Rejected  (exit, only from step 1 or 2)
```

| Action | Route | Effect |
|---|---|---|
| Validate | `POST /api/admin/citizen-reports/{id}/validate` | `Submitted` → `Pending Validation` (and `AdminWebController::reportsValidate` does the same) |
| Assign office | `POST /api/admin/citizen-reports/{id}/assign` | → `Assigned to Office`, `is_public = true` |
| Set status | `POST /api/admin/citizen-reports/{id}/status` | → any of `STATUS_ORDER`, plus reject rules above |

`is_public` flips to `true` on Assigned / In Progress / Resolved and back to
`false` on Rejected. The public feed is `GET /api/mobile/reports/community`,
which only returns `is_public = true`.

There is no separate "approve" verb — validate + assign *is* the approval path.

---

## Role gate

`app/Http/Middleware/EnsureSuperAdmin.php`, registered as the `superadmin`
alias in `bootstrap/app.php:22`.

* **Safe methods pass.** `GET`/`HEAD`/`OPTIONS` are allowed for every
  authenticated role, because CEO and CENRO need to read the panel.
* **Every write needs `role === 'super_admin'`.** `POST`/`PUT`/`PATCH`/
  `DELETE` returns JSON `{success:false, message:'Super administrator access is
  required.'}` with **403** on `api/*`, or a flashed error redirect elsewhere.

Attached to:

* the whole `/api/admin/*` group (`routes/api.php:77`)
* the whole `/admin/*` Blade group (`routes/web.php:15`)
* the three `/api/users` mutation routes only — `GET /api/users` stays open

`/api/users` POST/PUT/DELETE is gated because it is a privilege escalation:
without the gate, any authenticated account could mint a `super_admin`.

Roles are a MySQL enum: `super_admin | ceo | cenro` (there is no `staff`).

Test accounts:

| Email | Password | Role |
|---|---|---|
| `admin@civilwatch.ph` | `<your-admin-password>` | `super_admin` |
| `ceo@civilwatch.ph` | `<your-ceo-password>` | `ceo` |

---

## Notifications feed

The bell in the prototype navbar reads `citizen_notifications` — the shared
organisation feed, **not** a per-user inbox. There is no `user_id` filter.

| Endpoint | Shape |
|---|---|
| `GET /api/notifications` | `{success, data:{notifications[], unread_count}}` |
| `GET /api/notifications/unread-count` | `{success, data:{unread_count}}` — polled every 30s (`app.js:627`) |
| `POST /api/notifications/{id}/read`, `POST /api/notifications/read-all` | mark read |
| `DELETE /api/notifications`, `DELETE /api/notifications/{id}` | clear |

`app.js:575` renders each item from `type`, `message`, `created_at`,
`is_read` and maps `type` through `iconMap`
(`report_submitted | report_assigned | status_update | report_resolved |
system`). Read state is global: marking one read marks it read for everyone.

The legacy `notifications` table and the `Notification` model no longer exist.

---

## Analytics endpoints

Seven routes under `/api/analytics*`, all served by `AnalyticsController`
against `CitizenReport`.

| Route | Consumed by |
|---|---|
| `GET /api/analytics/summary` | `app.js:372` — sidebar pending badge |
| `GET /api/analytics` (all seven in one) | analytics pages |
| `.../status-distribution`, `/by-category`, `/top-issues`, `/top-barangays`, `/weekly-trend`, `/monthly-trend` | charts |

Statuses are the real enum values (`Submitted`, `Pending Validation`,
`Assigned to Office`, `In Progress`, `Resolved`, `Rejected`). Categories are
`Infrastructure | Environment | Others`. `top-issues` groups by `concern`, not
`title`. Role scoping joins `assignedOffice` on `abbreviation` (`CEO`/`CENRO`).

---

## Verification commands

```bash
cd prc/laravel

# lint everything touched
php -l routes/api.php && php -l routes/web.php && php -l bootstrap/app.php
php -l app/Http/Middleware/EnsureSuperAdmin.php
php -l app/Http/Controllers/AnalyticsController.php
php -l app/Http/Controllers/NotificationController.php

# route inventory (77 routes; no api/reports left)
php artisan route:list | tail -2
php artisan route:list --json | python3 -c \
  "import sys,json;r=json.load(sys.stdin);print(sum(1 for x in r if 'EnsureSuperAdmin' in str(x['middleware'])),'gated')"

# live gate check — ceo writes must 403, reads must 200
TOK=$(curl -s -X POST 127.0.0.1:8000/api/login -H 'Content-Type: application/json' \
  -d '{"email":"ceo@civilwatch.ph","password":"<your-ceo-password>"}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $TOK" \
  127.0.0.1:8000/api/admin/citizen-reports                 # 200
curl -s -o /dev/null -w '%{http_code}\n' -X POST -H "Authorization: Bearer $TOK" \
  -H 'Content-Type: application/json' -d '{"name":"x","abbreviation":"x"}' \
  127.0.0.1:8000/api/admin/offices                         # 403

# ENUM really contains Rejected
mariadb --socket=$HOME/.local/var/mysql/mysql.sock -u root -D civilwatch \
  -e "SELECT COLUMN_TYPE FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA='civilwatch' AND TABLE_NAME='citizen_reports'
      AND COLUMN_NAME='status';"
```

**Not verified:** no Flutter SDK, no Dart, no emulator in this environment —
every change under `civ-main/` is static review only (brace balance + diff
reading). `tree_sitter_php` cannot build on Termux, so Laravel PHP is absent
from the graphify graph; read those files directly.

## State machine and map scope (QA batch 025)

- Status values: Submitted → Pending Validation → Assigned to Office → In Progress → Resolved, and Rejected (terminal before assignment in allowed rejectable states).
- Admin GIS (`/api/admin/citizen-reports/map`): now includes Pending Validation (is_public + coords) in addition to Assigned/In Progress/Resolved. Submitted and Rejected are not returned by the map endpoint.
- Admin GIS pins are colored by **status**; emoji on pins are chosen by **category** (Infrastructure vs Environmental/others) — this differs from the public/community mobile map which colors/represents by category. Both are intentional.
