import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import 'events_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'registrations_screen.dart';
import 'riwayat_screen.dart';
import 'tickets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService.instance;
  int _index = 0;
  int _unreadCount = 0;

  static const _titles = [
    'Beranda',
    'Pendaftaran',
    'Tiket Saya',
    'Notifikasi',
    'Profil',
  ];

  @override
  void initState() {
    super.initState();
    _showUnreadNotifications();
  }

  Future<void> _showUnreadNotifications() async {
    try {
      final result = await _api.getNotifications();
      if (!mounted) return;
      final unread = result.items.where((n) => !n.isRead).toList();
      if (_unreadCount != unread.length) {
        setState(() => _unreadCount = unread.length);
      }
      if (unread.isEmpty) return;
      _showUnreadDialog(unread);
    } on ApiException {
      // abaikan bila gagal memuat notifikasi
    }
  }

  void _showUnreadDialog(List<AppNotification> unread) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.notifications_active,
          color: theme.colorScheme.secondary,
        ),
        title: const Text('Notifikasi Belum Dibaca'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: unread.length,
            itemBuilder: (context, index) {
              final notification = unread[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.circle,
                  size: 12,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  notification.title ?? 'Notifikasi',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  notification.message ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _index = 3);
            },
            child: const Text('Lihat Semua'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const EventsScreen(),
      const RegistrationsScreen(),
      const TicketsScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Riwayat',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RiwayatScreen()),
              );
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 3) _showUnreadNotifications();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Pendaftaran',
          ),
          const NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Tiket',
          ),
          NavigationDestination(
            icon: _NotificationIcon(
              unread: _unreadCount,
              icon: Icons.notifications_outlined,
            ),
            selectedIcon: _NotificationIcon(
              unread: _unreadCount,
              icon: Icons.notifications,
            ),
            label: 'Notifikasi',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final int unread;
  final IconData icon;

  const _NotificationIcon({required this.unread, required this.icon});

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon);
    if (unread <= 0) return iconWidget;
    return Badge.count(
      count: unread,
      isLabelVisible: unread > 0,
      child: iconWidget,
    );
  }
}
