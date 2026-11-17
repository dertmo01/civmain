<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Staff-only gate for the admin / office API.
 *
 * Defence in depth behind the `sanctum` guard (config/auth.php), which is
 * bound to the users provider: even if that guard were ever misconfigured,
 * a Citizen token must never reach staff routes. Registered as the `staff`
 * alias in bootstrap/app.php and placed right after `auth:sanctum`.
 */
class EnsureStaff
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user instanceof User) {
            return response()->json([
                'success' => false,
                'message' => 'Staff access is required.',
            ], 403);
        }

        return $next($request);
    }
}
