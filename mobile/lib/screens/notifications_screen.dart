import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiService.instance;
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _api.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = result.items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _toggleRead(AppNotification notification) async {
    try {
      await _api.markNotificationRead(
        notification.id,
        isRead: !notification.isRead,
      );
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showDetails(AppNotification notification) async {
    if (notification.isRead) return;

    try {
      await _api.markNotificationRead(notification.id, isRead: true);
    } on ApiException {
      // gagal menandai dibaca, tetap tampilkan pop-up
    }
    if (!mounted) return;

    final theme = Theme.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.notifications_active,
          color: theme.colorScheme.secondary,
        ),
        title: Text(notification.title ?? 'Notifikasi'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.message ?? ''),
              if (notification.createdAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  notification.createdAt!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_notifications.isEmpty) {
      return const Center(child: Text('Belum ada notifikasi'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return Card(
            color: notification.isRead
                ? null
                : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: ListTile(
              onTap: () => _showDetails(notification),
              leading: Icon(
                notification.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active,
                color: notification.isRead
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                notification.title ?? 'Notifikasi',
                style: TextStyle(
                  fontWeight:
                      notification.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Text(notification.message ?? ''),
              trailing: IconButton(
                icon: Icon(
                  notification.isRead
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_unread_outlined,
                ),
                tooltip:
                    notification.isRead ? 'Tandai belum dibaca' : 'Tandai dibaca',
                onPressed: () => _toggleRead(notification),
              ),
            ),
          );
        },
      ),
    );
  }
}
