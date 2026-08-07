<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ticket;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TicketController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role === 'admin') {
            $tickets = Ticket::with(['registration.user:id,name,email', 'registration.event:id,title'])
                ->orderByDesc('created_at')
                ->paginate(10);
        } else {
            $tickets = Ticket::with(['registration:id,event_id,user_id,status', 'registration.event:id,title,event_date,location'])
                ->whereHas('registration', fn ($q) => $q->where('user_id', $user->id))
                ->orderByDesc('created_at')
                ->paginate(10);
        }

        return response()->json($tickets);
    }

    public function show(Request $request, Ticket $ticket): JsonResponse
    {
        $user = $request->user();

        abort_unless(
            $user->role === 'admin' || $ticket->registration->user_id === $user->id,
            403,
            'Anda tidak memiliki akses ke tiket ini.'
        );

        $ticket->load(['registration.user', 'registration.event.category']);

        return response()->json(['data' => $ticket]);
    }
}
