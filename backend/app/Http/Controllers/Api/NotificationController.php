<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $notifications = $request->user()->notifications()
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json($notifications);
    }

    public function markRead(Request $request, Notification $notification): JsonResponse
    {
        abort_unless($notification->user_id === $request->user()->id, 403);

        $validated = $request->validate([
            'is_read' => ['sometimes', 'boolean'],
        ]);

        $notification->update([
            'is_read' => $validated['is_read'] ?? true,
        ]);

        return response()->json([
            'message' => 'Status notifikasi diperbarui',
            'data' => $notification,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        abort_unless($request->user()->role === 'admin', 403, 'Hanya admin yang dapat mengirim notifikasi.');

        $validated = $request->validate([
            'user_id' => ['required', 'exists:users,id'],
            'title' => ['required', 'string', 'max:100'],
            'message' => ['nullable', 'string'],
        ]);

        $notification = Notification::create($validated);

        return response()->json([
            'message' => 'Notifikasi berhasil dikirim',
            'data' => $notification,
        ], 201);
    }
}
