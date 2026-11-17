<?php

use App\Http\Controllers\AnalyticsController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\Mobile\MobileAuthController;
use App\Http\Controllers\Mobile\MobileReportController;
use App\Http\Controllers\Mobile\MobileNotificationController;
use App\Http\Controllers\Mobile\MobileAnnouncementController;
use App\Http\Controllers\Admin\AdminCitizenReportController;
use App\Http\Controllers\Admin\AdminOfficeController;
use App\Http\Controllers\Admin\AdminAnnouncementController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes — CivilWatch
|--------------------------------------------------------------------------
|
| /api/mobile/*  — Flutter citizen app  (auth guard: 'citizen')
| /api/admin/*   — Admin web panel      (auth guard: 'sanctum' / staff users)
| /api/*         — Legacy admin API     (unchanged)
|
|--------------------------------------------------------------------------
*/

// ═══════════════════════════════════════════════════════════════════════
// HEALTH CHECK
// ═══════════════════════════════════════════════════════════════════════

Route::get('/ping', fn() => response()->json([
    'success' => true,
    'message' => 'CivilWatch API is running.',
]));

// ═══════════════════════════════════════════════════════════════════════
// MOBILE — CITIZEN APP (Flutter)
// ═══════════════════════════════════════════════════════════════════════

Route::prefix('mobile')->name('mobile.')->group(function () {

    // ── Auth (public — no token needed) ───────────────────────────────
    Route::prefix('auth')->name('auth.')->group(function () {
        Route::post('login',      [MobileAuthController::class, 'login']);
        Route::post('send-otp',   [MobileAuthController::class, 'sendOtp']);
        Route::post('verify-otp', [MobileAuthController::class, 'verifyOtp']);
        Route::post('verify-reset-otp', [MobileAuthController::class, 'verifyResetOtp']);
        Route::post('reset-pin',  [MobileAuthController::class, 'resetPin']);
        Route::post('register',   [MobileAuthController::class, 'register']);
    });

    // ── Announcements (public — readable without login) ───────────────
    Route::get('announcements', [MobileAnnouncementController::class, 'index']);

    // ── Public — no login required ────────────────────────────────────
    // NOTE: /community must be registered BEFORE the auth group's /{id}
    Route::get('reports/community', [MobileReportController::class, 'community']);

    // ── Protected — requires citizen Sanctum token ────────────────────
    Route::middleware('auth:citizen')->group(function () {

        // Auth
        Route::post('auth/logout', [MobileAuthController::class, 'logout']);
        Route::get('auth/me',      [MobileAuthController::class, 'me']);
        Route::get('reports',           [MobileReportController::class, 'index']);
        Route::post('reports',          [MobileReportController::class, 'store']);
        Route::get('reports/{id}',      [MobileReportController::class, 'show']);

        // Notifications
        Route::get('notifications',                       [MobileNotificationController::class, 'index']);
        Route::post('notifications/mark-all-read',        [MobileNotificationController::class, 'markAllRead']);
        Route::post('notifications/{id}/read',            [MobileNotificationController::class, 'markRead']);
    });
});

// ═══════════════════════════════════════════════════════════════════════
// ADMIN — WEB PANEL API (staff users — email/password → Sanctum token)
// ═══════════════════════════════════════════════════════════════════════

// Writes here are super_admin only — see App\Middleware\EnsureSuperAdmin.
// Reads stay open to every authenticated role (CEO/CENRO need the data).
// Exception: POST citizen-reports/{id}/status is deliberately NOT here — the
// assigned office (CEO/CENRO) drives that transition, so it lives in the
// auth-only group below where updateStatus() enforces office ownership.
Route::prefix('admin')->name('admin.')->middleware(['auth:sanctum', 'staff', 'superadmin'])->group(function () {

    // Citizen reports management
    Route::get('citizen-reports/summary',      [AdminCitizenReportController::class, 'summary']);
    Route::get('citizen-reports/map',          [AdminCitizenReportController::class, 'map']);
    Route::get('citizen-reports',              [AdminCitizenReportController::class, 'index']);
    Route::get('citizen-reports/{id}',         [AdminCitizenReportController::class, 'show']);
    Route::post('citizen-reports/{id}/validate', [AdminCitizenReportController::class, 'validate']);
    Route::post('citizen-reports/{id}/assign', [AdminCitizenReportController::class, 'assign']);

    // Users — stats table on public/users.html
    Route::get('users',          [UserController::class, 'index']);

    // Government offices
    Route::get('offices',        [AdminOfficeController::class, 'index']);
    Route::post('offices',       [AdminOfficeController::class, 'store']);
    Route::put('offices/{id}',   [AdminOfficeController::class, 'update']);
    Route::delete('offices/{id}',[AdminOfficeController::class, 'destroy']);

    // Announcements
    Route::get('announcements',           [AdminAnnouncementController::class, 'index']);
    Route::post('announcements',          [AdminAnnouncementController::class, 'store']);
    Route::put('announcements/{id}',      [AdminAnnouncementController::class, 'update']);
    Route::delete('announcements/{id}',   [AdminAnnouncementController::class, 'destroy']);
});

// ═══════════════════════════════════════════════════════════════════════
// LEGACY ADMIN API (unchanged — staff email/password workflow)
// ═══════════════════════════════════════════════════════════════════════

Route::post('/login', [AuthController::class, 'login']);

// `staff` rejects any non-User token (see App\Http\Middleware\EnsureStaff).
Route::middleware(['auth:sanctum', 'staff'])->group(function () {

    // Auth
    Route::get('/user',   [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Users (super_admin only) — creating or changing staff accounts is a
    // privilege escalation, so writes are gated; listing stays readable.
    Route::get('/users',         [UserController::class, 'index']);
    Route::post('/users',        [UserController::class, 'store'])->middleware('superadmin');
    Route::get('/users/{id}',    [UserController::class, 'show']);
    Route::put('/users/{id}',    [UserController::class, 'update'])->middleware('superadmin');
    Route::delete('/users/{id}', [UserController::class, 'destroy'])->middleware('superadmin');

    // Reports (admin-side) live at /api/admin/citizen-reports — the legacy
    // /api/reports* block against the dropped `reports` table was removed.

    // Analytics
    Route::get('/analytics',                      [AnalyticsController::class, 'full']);
    Route::get('/analytics/summary',              [AnalyticsController::class, 'summary']);
    Route::get('/analytics/status-distribution',  [AnalyticsController::class, 'statusDistribution']);
    Route::get('/analytics/by-category',          [AnalyticsController::class, 'byCategory']);
    Route::get('/analytics/top-issues',           [AnalyticsController::class, 'topIssues']);
    Route::get('/analytics/top-barangays',        [AnalyticsController::class, 'topBarangays']);
    Route::get('/analytics/weekly-trend',         [AnalyticsController::class, 'weeklyTrend']);
    Route::get('/analytics/monthly-trend',        [AnalyticsController::class, 'monthlyTrend']);

    // Notifications (admin-side)
    Route::get('/notifications/unread-count',     [NotificationController::class, 'unreadCount']);
    Route::get('/notifications',                  [NotificationController::class, 'index']);
    Route::delete('/notifications',               [NotificationController::class, 'destroyAll']);
    Route::post('/notifications/{id}/read',       [NotificationController::class, 'markRead']);
    Route::delete('/notifications/{id}',          [NotificationController::class, 'destroy']);
    Route::post('/notifications/read-all',        [NotificationController::class, 'markAllRead']);

    // Priority management is restricted to authorized personnel of the
    // office currently assigned to the report (no super_admin access).
    Route::post('/admin/citizen-reports/{id}/priority',
        [AdminCitizenReportController::class, 'updatePriority']);

    // Status updates are shared: the super admin can drive any transition
    // (from Monitoring) and the assigned office can progress its own reports.
    // It sits outside the super_admin gate for that reason; updateStatus()
    // checks role + office ownership, and offices may only reach Assigned,
    // In Progress or Resolved.
    Route::post('/admin/citizen-reports/{id}/status',
        [AdminCitizenReportController::class, 'updateStatus']);
});
