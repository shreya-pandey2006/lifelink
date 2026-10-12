import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'ui.dart';
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bg;
    final Color fg;
    switch (status) {
      case 'matched':
        label = 'MATCHED';
        bg = const Color(0xFFE3F4E8);
        fg = const Color(0xFF1E7A3C);
      case 'fulfilled':
        label = 'FULFILLED';
        bg = const Color(0xFFD5EEDC);
        fg = const Color(0xFF14602D);
      case 'cancelled':
        label = 'CANCELLED';
        bg = const Color(0xFFEFEBF0);
        fg = kMuted;
      case 'expired':
        label = 'EXPIRED';
        bg = const Color(0xFFEFEBF0);
        fg = kMuted;
      default:
        label = 'OPEN';
        bg = kAmberSoft;
        fg = kAmber;
    }
    return Pill(label, background: bg, foreground: fg);
  }
}