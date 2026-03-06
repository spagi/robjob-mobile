<?php

namespace App\Http\Controllers\Api\Auth;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Mobile login endpoint — extends standard LoginController behaviour
 * but additionally returns the Bearer token in the JSON response body,
 * so mobile clients can store it without relying on HttpOnly cookies.
 */
class MobileLoginController extends LoginController
{
    /**
     * Handle a mobile login request.
     *
     * POST /api/v1/auth/mobile/login
     *
     * Request body:
     *   { "email": "string", "password": "string" }
     *
     * Response body:
     *   {
     *     "data": { ...same user data as standard /auth/login... },
     *     "token": "1|abc123xyz..."
     *   }
     */
    public function __invoke(Request $request): JsonResponse
    {
        // Re-use the parent login flow (validation, credentials check, etc.)
        $response = parent::__invoke($request);

        // After successful authentication the guard holds the issued token
        $bearer = \resolveGuard()->databaseToken->bearer;

        // Merge the plain-text bearer into the JSON response
        $responseData = $response->getData(assoc: true);
        $responseData['token'] = $bearer;

        return response()->json($responseData, $response->status());
    }
}
