<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        // ── Default Super Admin ────────────────────────────────────────────
        // Never hard-code this password: it would be the same, publicly known
        // password on every install. Set SEED_ADMIN_PASSWORD in .env, or a
        // random one is generated and printed once below.
        $password = env('SEED_ADMIN_PASSWORD') ?: Str::password(16);

        $admin = User::firstOrCreate(
            ['email' => 'admin@civilwatch.ph'],
            [
                'name'          => 'Super Administrator',
                'password_hash' => Hash::make($password),
                'role'          => 'super_admin',
                'office'        => null,
                'is_active'     => true,
            ]
        );

        // ── Government Offices ─────────────────────────────────────────────
        $this->call(GovernmentOfficeSeeder::class);

        // ── Sample Announcements ───────────────────────────────────────────
        $this->call(AnnouncementSeeder::class);

        $this->command->info('');
        $this->command->info('✓ CivilWatch database seeded successfully.');
        if ($admin->wasRecentlyCreated) {
            $this->command->warn("  Admin login: admin@civilwatch.ph / {$password}");
            $this->command->warn('  Shown once. Store it safely and change it after first login.');
        } else {
            $this->command->info('  Admin account already existed; its password was not changed.');
        }
    }
}
