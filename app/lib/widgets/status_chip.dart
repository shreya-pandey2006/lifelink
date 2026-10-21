import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bg;
    final Color fg;
    final IconData? icon;

    switch (status.toLowerCase()) {
      case 'matched':
        label = 'MATCHED';
        bg = const Color(0xFFFDE8E8);
        fg = const Color(0xFFBA1A1A);
        icon = Icons.radio_button_checked;
        break;
      case 'fulfilled':
        label = 'FULFILLED';
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        label = 'CANCELLED';
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        icon = null;
        break;
      case 'expired':
        label = 'EXPIRED';
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        icon = null;
        break;
      case 'open':
      default:
        label = 'OPEN';
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        icon = Icons.circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: icon == Icons.circle ? 6 : 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}