import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool filled;

  const StatusBadge({
    super.key,
    required this.status,
    this.filled = true,
  });

  Color _color(BuildContext context) {
    switch (status) {
      case 'Aktif':
        return Colors.green;
      case 'Menunggu':
        return Colors.orange;
      case 'Diterima':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      case 'Selesai':
        return Colors.blueGrey;
      case 'Ditutup':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.15) : Colors.transparent,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
