<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EventController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Event::with('category')
            ->withCount([
                'registrations as registered_count' => fn ($q) => $q->where('status', '!=', 'Ditolak'),
            ]);

        if ($request->filled('category_id')) {
            $query->where('category_id', $request->integer('category_id'));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        } elseif (auth()->user()?->role !== 'admin') {
            $query->where('status', 'Aktif');
        }

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', '%'.$search.'%')
                    ->orWhere('location', 'like', '%'.$search.'%')
                    ->orWhere('organizer', 'like', '%'.$search.'%');
            });
        }

        $events = $query->orderByDesc('event_date')->paginate(10);

        return response()->json($events);
    }

    public function show(Event $event): JsonResponse
    {
        $event->load('category');

        return response()->json([
            'data' => $event,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $this->authorizeAdmin();

        $validated = $request->validate([
            'category_id' => ['required', 'exists:categories,id'],
            'title' => ['required', 'string', 'max:150'],
            'description' => ['nullable', 'string'],
            'organizer' => ['nullable', 'string', 'max:100'],
            'location' => ['nullable', 'string', 'max:150'],
            'event_date' => ['nullable', 'date'],
            'start_time' => ['nullable', 'date_format:H:i'],
            'end_time' => ['nullable', 'date_format:H:i'],
            'quota' => ['required', 'integer', 'min:0'],
            'image' => ['nullable', 'string', 'max:255'],
            'status' => ['sometimes', 'in:Aktif,Selesai,Ditutup'],
        ]);

        $event = Event::create($validated);
        $event->load('category');

        return response()->json([
            'message' => 'Event berhasil dibuat',
            'data' => $event,
        ], 201);
    }

    public function update(Request $request, Event $event): JsonResponse
    {
        $this->authorizeAdmin();

        $validated = $request->validate([
            'category_id' => ['sometimes', 'exists:categories,id'],
            'title' => ['sometimes', 'string', 'max:150'],
            'description' => ['nullable', 'string'],
            'organizer' => ['nullable', 'string', 'max:100'],
            'location' => ['nullable', 'string', 'max:150'],
            'event_date' => ['nullable', 'date'],
            'start_time' => ['nullable', 'date_format:H:i'],
            'end_time' => ['nullable', 'date_format:H:i'],
            'quota' => ['sometimes', 'integer', 'min:0'],
            'image' => ['nullable', 'string', 'max:255'],
            'status' => ['sometimes', 'in:Aktif,Selesai,Ditutup'],
        ]);

        $event->update($validated);
        $event->load('category');

        return response()->json([
            'message' => 'Event berhasil diperbarui',
            'data' => $event,
        ]);
    }

    public function destroy(Event $event): JsonResponse
    {
        $this->authorizeAdmin();

        $event->delete();

        return response()->json(['message' => 'Event berhasil dihapus']);
    }

    private function authorizeAdmin(): void
    {
        abort_unless(auth()->user()?->role === 'admin', 403, 'Hanya admin yang dapat melakukan aksi ini.');
    }
}
