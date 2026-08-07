import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/event.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../widgets/event_image.dart';
import '../../widgets/status_badge.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _api = ApiService.instance;
  Event? _event;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final event = await _api.getEvent(widget.eventId);
      if (mounted) {
        setState(() {
          _event = event;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _register() async {
    final event = _event;
    if (event == null) return;

    if (!event.isOpen) {
      _showMessage('Event sudah tidak menerima pendaftaran.');
      return;
    }
    if (event.isFull) {
      _showMessage('Kuota event sudah penuh.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daftar Event'),
        content: Text('Anda yakin ingin mendaftar pada event "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Daftar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await _api.createRegistration(widget.eventId);
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage('Pendaftaran berhasil! Menunggu konfirmasi admin.');
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(e.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(String? value) {
    if (value == null) return 'Belum ditentukan';
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  String _formatTime(String? value) {
    if (value == null) return '';
    return value.length >= 5 ? value.substring(0, 5) : value;
  }

  String _formatTimeRange(String? start, String? end) {
    final s = _formatTime(start);
    final e = _formatTime(end);
    if (s.isEmpty && e.isEmpty) return 'Belum ditentukan';
    if (e.isEmpty) return s;
    return '$s - $e';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = _event;

    final canRegister = event != null && event.isOpen && !event.isFull;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Event')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildDetail(theme),
      bottomNavigationBar: event == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _submitting ? null : _register,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          canRegister
                              ? 'Daftar Sekarang'
                              : 'Pendaftaran Ditutup',
                        ),
                ),
              ),
            ),
    );
  }

  Widget _buildDetail(ThemeData theme) {
    final event = _event!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: EventImage(event: event, height: 200, width: double.infinity),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                event.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            StatusBadge(status: event.status),
          ],
        ),
        const SizedBox(height: 8),
        if (event.category != null)
          Text(
            'Kategori: ${event.category!.categoryName}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 16),
        _InfoTile(
          icon: Icons.calendar_today_outlined,
          label: 'Tanggal',
          value: _formatDate(event.eventDate),
        ),
        _InfoTile(
          icon: Icons.schedule,
          label: 'Waktu',
          value: _formatTimeRange(event.startTime, event.endTime),
        ),
        _InfoTile(
          icon: Icons.location_on_outlined,
          label: 'Lokasi',
          value: event.location ?? 'Belum ditentukan',
        ),
        _InfoTile(
          icon: Icons.business_outlined,
          label: 'Penyelenggara',
          value: event.organizer ?? 'Belum ditentukan',
        ),
        _InfoTile(
          icon: Icons.people_outline,
          label: 'Kuota',
          value: event.quota == 0
              ? '${event.registeredCount} terdaftar (Unlimited)'
              : '${event.registeredCount} / ${event.quota} terdaftar',
        ),
        const SizedBox(height: 16),
        Text('Deskripsi', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          event.description ?? 'Belum ada deskripsi.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}


class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}
