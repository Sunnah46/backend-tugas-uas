<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Notification;
use App\Models\Registration;
use App\Models\Ticket;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class RegistrationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role === 'admin') {
            $registrations = Registration::with(['user:id,name,email,phone', 'event:id,title,event_date,location'])
                ->orderByDesc('created_at')
                ->paginate(10);
        } else {
            $registrations = Registration::with(['event:id,title,event_date,location,status', 'ticket'])
                ->where('user_id', $user->id)
                ->orderByDesc('created_at')
                ->paginate(10);
        }

        return response()->json($registrations);
    }

    public function show(Request $request, Registration $registration): JsonResponse
    {
        $user = $request->user();

        abort_unless(
            $user->role === 'admin' || $registration->user_id === $user->id,
            403,
            'Anda tidak memiliki akses ke pendaftaran ini.'
        );

        $registration->load(['user', 'event.category', 'ticket']);

        return response()->json(['data' => $registration]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'event_id' => ['required', 'exists:events,id'],
        ]);

        $event = Event::findOrFail($validated['event_id']);

        if ($event->status !== 'Aktif') {
            return response()->json([
                'message' => 'Event sudah tidak menerima pendaftaran.',
            ], 422);
        }

        $already = Registration::where('user_id', $user->id)
            ->where('event_id', $event->id)
            ->exists();

        if ($already) {
            return response()->json([
                'message' => 'Anda sudah terdaftar pada event ini.',
            ], 422);
        }

        $activeCount = $event->registrations()
            ->where('status', '!=', 'Ditolak')
            ->count();

        if ($event->quota > 0 && $activeCount >= $event->quota) {
            return response()->json([
                'message' => 'Kuota event sudah penuh.',
            ], 422);
        }

        $registration = Registration::create([
            'user_id' => $user->id,
            'event_id' => $event->id,
            'registration_date' => now()->toDateString(),
            'status' => 'Menunggu',
        ]);

        $registration->load('event');

        return response()->json([
            'message' => 'Pendaftaran berhasil, menunggu konfirmasi admin.',
            'data' => $registration,
        ], 201);
    }

    public function update(Request $request, Registration $registration): JsonResponse
    {
        $this->authorizeAdmin();

        $validated = $request->validate([
            'status' => ['required', 'in:Diterima,Ditolak,Menunggu'],
        ]);

        $registration->update(['status' => $validated['status']]);

        if ($validated['status'] === 'Diterima' && ! $registration->ticket) {
            $this->generateTicket($registration);
            $this->notify($registration->user_id, 'Pendaftaran Diterima',
                "Selamat! Pendaftaran Anda untuk event \"{$registration->event->title}\" telah diterima.");
        }

        if ($validated['status'] === 'Ditolak') {
            $this->notify($registration->user_id, 'Pendaftaran Ditolak',
                "Mohon maaf, pendaftaran Anda untuk event \"{$registration->event->title}\" ditolak.");
        }

        $registration->load(['user:id,name,email', 'event:id,title', 'ticket']);

        return response()->json([
            'message' => 'Status pendaftaran berhasil diperbarui',
            'data' => $registration,
        ]);
    }

    public function destroy(Request $request, Registration $registration): JsonResponse
    {
        $user = $request->user();

        abort_unless(
            $user->role === 'admin' || $registration->user_id === $user->id,
            403,
            'Anda tidak memiliki akses ke pendaftaran ini.'
        );

        $registration->delete();

        return response()->json(['message' => 'Pendaftaran berhasil dibatalkan']);
    }

    private function generateTicket(Registration $registration): void
    {
        $ticketCode = strtoupper('EVT-'.$registration->event_id.'-'.$registration->id.'-'.Str::random(6));

        Ticket::create([
            'registration_id' => $registration->id,
            'ticket_code' => $ticketCode,
            'qr_code' => $ticketCode,
        ]);
    }

    private function notify(int $userId, string $title, string $message): void
    {
        Notification::create([
            'user_id' => $userId,
            'title' => $title,
            'message' => $message,
        ]);
    }

    private function authorizeAdmin(): void
    {
        abort_unless(auth()->user()?->role === 'admin', 403, 'Hanya admin yang dapat melakukan aksi ini.');
    }
}
