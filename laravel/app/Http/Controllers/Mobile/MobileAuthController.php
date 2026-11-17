<?php

namespace App\Http\Controllers\Mobile;

use App\Http\Controllers\Controller;
use App\Models\Citizen;
use App\Models\OtpCode;
use App\Services\UniSmsService;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class MobileAuthController extends Controller
{
    // ─────────────────────────────────────────────────────────────────────
    // POST /api/mobile/auth/login
    // Body: { phone, pin }
    // Direct phone + PIN login — no OTP required for returning users.
    // ─────────────────────────────────────────────────────────────────────
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'phone' => ['required', 'string'],
            'pin'   => ['required', 'string', 'regex:/^\d{6}$/'],
        ]);

        $normalized = $this->normalizePhone($request->phone);

        // Find citizen by phone
        $citizen = Citizen::where('phone', $normalized)->first();

        if (! $citizen) {
            return response()->json([
                'success' => false,
                'message' => 'No account found with that mobile number.',
            ], 401);
        }

        // Verify PIN
        if (! Hash::check($request->pin, $citizen->pin_hash)) {
            return response()->json([
                'success' => false,
                'message' => 'Incorrect PIN. Please try again.',
            ], 401);
        }

        if (! $citizen->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'Your account has been deactivated.',
            ], 403);
        }

        // Revoke old tokens and issue a fresh one
        $citizen->tokens()->delete();
        $token = $citizen->createToken('mobile')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful.',
            'data'    => [
                'token'   => $token,
                'citizen' => $this->citizenResponse($citizen),
            ],
        ]);
    }

    // ─────────────────────────────────────────────────────────────────────
    // POST /api/mobile/auth/send-otp
    // Body: { phone: "09XXXXXXXXX" }
    // Generates a 6-digit OTP and stores it, then sends it by real SMS via
    // UniSMS (docs/TASKS.md task 1) when UNISMS_SECRET_KEY is configured.
    // With no key the old dev behaviour stays: the code is echoed in the
    // response while APP_DEBUG=true (never in production).
    // ─────────────────────────────────────────────────────────────────────
    public function sendOtp(Request $request): JsonResponse
    {
        $request->validate([
            'phone' => ['required', 'string', 'regex:/^(0|\+63|63)?9\d{9}$/'],
        ]);

        $normalized = $this->normalizePhone($request->phone);

        // Generate a random 6-digit OTP
        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        // Store OTP (invalidates any previous unused ones for this number)
        OtpCode::issue($normalized, $code);

        // UniSMS (docs/TASKS.md task 1): real SMS when configured, honest
        // failure signals, and the debug echo gated behind APP_DEBUG.
        $provider = app(UniSmsService::class);
        $sms      = null;

        if ($provider->configured()) {
            $sms = $provider->send(
                $normalized,
                "CivilWatch: your verification code is {$code}. It expires in 5 minutes.",
                ['purpose' => 'otp', 'app' => 'civilwatch'],
            );

            if (! $sms['ok']) {
                Log::warning('UniSMS OTP send failed', [
                    'phone'  => $normalized,
                    'status' => $sms['status'],
                    'reason' => $sms['error'],
                ]);
            }
        }

        $data = [
            'phone'    => $normalized,
            'sms_sent' => (bool) ($sms['ok'] ?? false),
        ];

        if (! $provider->configured()) {
            $data['sms_error'] = 'UniSMS not configured (UNISMS_SECRET_KEY missing).';
        } elseif (! $sms['ok']) {
            $data['sms_error'] = $sms['error'];
        }

        // Dev autofill (the Flutter OTP screen uses it only when present).
        // Echoing the code hands account takeover to whoever calls send-otp,
        // so it requires BOTH a local environment AND debug — APP_DEBUG alone
        // is not enough, because a server deployed from .env.example has it on.
        $echoOtp = app()->environment('local') && config('app.debug');

        if ($echoOtp) {
            $data['otp'] = $code;
        }

        // No key + no echo = the user could never receive the code: fail honestly.
        if (! $provider->configured() && ! $echoOtp) {
            return response()->json([
                'success' => false,
                'message' => 'SMS service is not configured (UNISMS_SECRET_KEY missing).',
            ], 503);
        }

        // Sending was attempted and failed while the echo is off: don't fake success.
        if ($sms && ! $sms['ok'] && ! $echoOtp) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to send the verification SMS. Please try again.',
            ], 502);
        }

        return response()->json([
            'success' => true,
            'message' => ($sms && $sms['ok']) ? 'OTP sent via SMS.' : 'OTP generated successfully.',
            'data'    => $data,
        ]);
    }

    // ─────────────────────────────────────────────────────────────────────
    // POST /api/mobile/auth/verify-otp
    // Body: { phone, otp }
    // Returns: { token, isNewUser }
    // ─────────────────────────────────────────────────────────────────────
    public function verifyOtp(Request $request): JsonResponse
    {
        $request->validate([
            'phone' => ['required', 'string'],
            'otp'   => ['required', 'string', 'size:6'],
        ]);

        $normalized = $this->normalizePhone($request->phone);
        $otpRecord  = OtpCode::findValid($normalized, $request->otp);

        if (! $otpRecord) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired OTP.',
            ], 422);
        }

        // Mark OTP as used
        $otpRecord->update(['is_used' => true]);

        // Check if citizen already exists
        $citizen   = Citizen::where('phone', $normalized)->first();
        $isNewUser = ! $citizen;

        if ($citizen) {
            // Returning user — issue token immediately
            $token = $citizen->createToken('mobile')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'OTP verified.',
                'data'    => [
                    'token'     => $token,
                    'isNewUser' => false,
                    'citizen'   => $this->citizenResponse($citizen),
                ],
            ]);
        }

        // New user — let them proceed to registration
        return response()->json([
            'success' => true,
            'message' => 'OTP verified. Please complete registration.',
            'data'    => [
                'token'     => null,
                'isNewUser' => true,
                'phone'     => $normalized,
            ],
        ]);
    }

    // ─────────────────────────────────────────────────────────────────────
    // POST /api/mobile/auth/verify-reset-otp
    // Body: { phone, otp }
    // Checks the OTP for a password reset WITHOUT consuming it, so the user
    // gets immediate feedback before choosing a new PIN. resetPin() then
    // consumes the same code atomically.
    // ─────────────────────────────────────────────────────────────────────
    public function verifyResetOtp(Request $request): JsonResponse
    {
        $request->validate([
            'phone' => ['required', 'string', 'regex:/^(0|\+63|63)?9\d{9}$/'],
            'otp'   => ['required', 'string', 'size:6'],
        ]);

        $normalized = $this->normalizePhone($request->phone);
        $citizen    = Citizen::where('phone', $normalized)->first();

        if (! $citizen) {
            return response()->json([
                'success' => false,
                'message' => 'No account found with that mobile number.',
            ], 404);
        }

        if (! $citizen->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'Your account has been deactivated.',
            ], 403);
        }

        if (! OtpCode::findValid($normalized, $request->otp)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired OTP.',
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'OTP verified.',
            'data'    => ['phone' => $normalized],
        ]);
    }

    // ─────────────────────────────────────────────────────────────────────
    // POST /api/mobile/auth/reset-pin
    // Body: { phone, otp, pin }
    // If the OTP is valid, replaces the citizen's PIN and revokes every
    // existing token so any stolen session is signed out.
    // ─────────────────────────────────────────────────────────────────────
    public function resetPin(Request $request): JsonResponse
    {
        $request->validate([
            'phone' => ['required', 'string', 'regex:/^(0|\+63|63)?9\d{9}$/'],
            'otp'   => ['required', 'string', 'size:6'],
            'pin'   => ['required', 'string', 'regex:/^\d{6}$/'],
        ]);

        $normalized = $this->normalizePhone($request->phone);
        $citizen    = Citizen::where('phone', $normalized)->first();

        if (! $citizen) {
            return response()->json([
                'success' => false,
                'message' => 'No account found with that mobile number.',
            ], 404);
        }

        if (! $citizen->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'Your account has been deactivated.',
            ], 403);
        }

        $otpRecord = OtpCode::findValid($normalized, $request->otp);

        if (! $otpRecord) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired OTP.',
            ], 422);
        }

        DB::transaction(function () use ($citizen, $otpRecord, $request) {
            $otpRecord->update(['is_used' => true]);
            $citizen->update(['pin_hash' => Hash::make($request->pin)]);
            $citizen->tokens()->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'PIN reset successfully. Please log in with your new PIN.',
        ]);
    }

    // ─────────────────────────────────────────────────────────────────────
    // POST /api/mobile/auth/register
    // Body: { fullName, email (optional), barangay, pin, phone }
    // ─────────────────────────────────────────────────────────────────────
    public function register(Request $request): JsonResponse
    {
        $normalized = $this->normalizePhone($request->phone ?? '');

        // ── Validation ────────────────────────────────────────────────────
        try {
            $request->validate([
                'fullName' => ['required', 'string', 'max:150', function ($attr, $val, $fail) {
                    if (count(array_filter(explode(' ', trim($val)))) < 2) {
                        $fail('Please enter both your first and last name.');
                    }
                }],
                'email'    => 'nullable|email|max:191|unique:citizens,email',
                'street'   => 'nullable|string|max:150',
                'purok'    => 'nullable|string|max:100',
                'barangay' => ['required', 'string', 'in:' . implode(',', self::BARANGAYS)],
                'city'     => 'nullable|string|max:100',
                'province' => 'nullable|string|max:100',
                'pin'      => ['required', 'string', 'regex:/^\d{6}$/'],
                'phone'    => [
                    'required', 'string',
                    function ($attr, $val, $fail) use ($normalized) {
                        if (Citizen::where('phone', $normalized)->exists()) {
                            $fail('This mobile number is already registered. Please sign in instead.');
                        }
                    },
                ],
            ]);
        } catch (ValidationException $e) {
            // Return first validation error as a clean, user-friendly message
            $first = collect($e->errors())->flatten()->first();
            return response()->json([
                'success' => false,
                'message' => $first,
                'errors'  => $e->errors(),
            ], 422);
        }

        // ── Create citizen + token ────────────────────────────────────────
        try {
            $citizen = Citizen::create([
                'full_name' => $request->fullName,
                'email'     => $request->email,
                'phone'     => $normalized,
                'street'    => $request->street ?: null,
                'purok'     => $request->purok ?: null,
                'barangay'  => $request->barangay,
                'city'      => $request->city ?: 'Digos City',
                'province'  => $request->province ?: 'Davao del Sur',
                'pin_hash'  => Hash::make($request->pin),
            ]);
        } catch (QueryException $e) {
            // Safety net for any race-condition duplicate key violation
            if ($e->errorInfo[1] === 1062) {
                return response()->json([
                    'success' => false,
                    'message' => 'This mobile number is already registered. Please sign in instead.',
                ], 422);
            }
            return response()->json([
                'success' => false,
                'message' => 'Registration failed. Please try again.',
            ], 500);
        }

        $token = $citizen->createToken('mobile')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Registration successful.',
            'data'    => [
                'token'     => $token,
                'isNewUser' => false,
                'citizen'   => $this->citizenResponse($citizen),
            ],
        ], 201);
    }

    // ─────────────────────────────────────────────────────────────────────
    // POST /api/mobile/auth/logout
    // ─────────────────────────────────────────────────────────────────────
    public function logout(Request $request): JsonResponse
    {
        $request->user('citizen')->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully.',
        ]);
    }

    // ─────────────────────────────────────────────────────────────────────
    // GET /api/mobile/auth/me
    // ─────────────────────────────────────────────────────────────────────
    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->citizenResponse($request->user('citizen')),
        ]);
    }

    // ─────────────────────────────────────────────────────────────────────
    // Private helpers
    // ─────────────────────────────────────────────────────────────────────

    private function citizenResponse(Citizen $citizen): array
    {
        return [
            'id'              => (string) $citizen->id,
            'fullName'        => $citizen->full_name,
            'phoneNumber'     => $citizen->phone,
            'street'          => $citizen->street,
            'purok'           => $citizen->purok,
            'barangay'        => $citizen->barangay,
            'city'            => $citizen->city,
            'province'        => $citizen->province,
            'joinedDate'      => $citizen->created_at?->toIso8601String(),
            'totalReports'    => $citizen->total_reports,
            'resolvedReports' => $citizen->resolved_reports,
            'avatarUrl'       => null,
        ];
    }

    /**
     * Normalise any Philippine phone number to 639XXXXXXXXX format.
     */
    private function normalizePhone(string $phone): string
    {
        $phone = preg_replace('/[\s\-\(\)]/', '', $phone);

        if (str_starts_with($phone, '+63')) return substr($phone, 1);
        if (str_starts_with($phone, '0'))   return '63' . substr($phone, 1);
        if (str_starts_with($phone, '9'))   return '63' . $phone;

        return $phone;
    }

    // Official 26 barangays of Digos City, Davao del Sur (PSA 2020 / PhilAtlas).
    // Keep in sync with AppStrings.barangays in the Flutter app.
    private const BARANGAYS = [
        'Aplaya', 'Balabag', 'Binaton', 'Cogon', 'Colorado', 'Dawis',
        'Dulangan', 'Goma', 'Igpit', 'Kapatagan', 'Kiagot', 'Lungag',
        'Mahayahay', 'Matti', 'Ruparan', 'San Agustin', 'San Jose',
        'San Miguel', 'San Roque', 'Sinawilan', 'Soong', 'Tiguman',
        'Tres de Mayo', 'Zone 1 (Pob.)', 'Zone 2 (Pob.)', 'Zone 3 (Pob.)',
    ];
}
