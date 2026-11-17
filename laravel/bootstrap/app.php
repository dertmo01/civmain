<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Laravel's default guest redirect is route('login'), but this app
        // defines no route with that name (the Blade login is 'admin.login').
        // The default callback therefore throws RouteNotFoundException from
        // inside Authenticate::unauthenticated() — *before* the exception
        // handler runs — so every unauthenticated browser hit on a protected
        // route 500s instead of redirecting. Point it at the real login route.
        $middleware->redirectGuestsTo(fn () => route('admin.login'));

        // Allow Flutter Web (Chrome) and the web admin to call the API
        // without CORS errors. In production, replace '*' with your
        // actual domain (e.g. 'https://civilwatch.gov.ph').
        $middleware->api(prepend: [
            \Illuminate\Http\Middleware\HandleCors::class,
        ]);

        $middleware->alias([
            'superadmin' => \App\Http\Middleware\EnsureSuperAdmin::class,
            'staff'      => \App\Http\Middleware\EnsureStaff::class,
        ]);

        $middleware->validateCsrfTokens(except: [
            'api/*',
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // API requests must get JSON errors, not the HTML login redirect.
        // Note: this only controls *rendering* an exception that was already
        // thrown. It cannot prevent RouteNotFoundException — that used to be
        // claimed here, but the exception originates in Authenticate's guest
        // redirect, which runs before the handler. See redirectGuestsTo above.
        $exceptions->shouldRenderJsonWhen(
            fn ($request) => $request->is('api/*') || $request->expectsJson()
        );
    })->create();
