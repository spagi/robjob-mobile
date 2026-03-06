<?php

// Add this route to routes/api.php inside the v1 prefix group,
// alongside the existing auth routes:

use App\Http\Controllers\Api\Auth\MobileLoginController;

// routes/api.php — inside Route::prefix('v1')->group(...)
Route::post('auth/mobile/login', MobileLoginController::class)
    ->name('auth.mobile.login');

// Full context (where to insert in routes/api.php):
// Route::prefix('v1')->group(function () {
//     Route::post('auth/login',        LoginController::class)->name('auth.login');
//     Route::post('auth/mobile/login', MobileLoginController::class)->name('auth.mobile.login'); // <-- add this line
//     Route::post('auth/logout',       LogoutController::class)->name('auth.logout')->middleware('auth');
//     ...
// });
