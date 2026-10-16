import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'ui.dart';
class UrgencyPill extends StatelessWidget {
  final int urgency;
  const UrgencyPill(this.urgency, {super.key});
  @override
  Widget build(BuildContext context) {
    switch (urgency) {
      case 3:
        return const Pill('CRITICAL', background: kPrimarySoft, foreground: kPrimaryDark);
      case 2:
        return const Pill('URGENT', background: kAmberSoft, foreground: kAmber);
      default:
        return const Pill('NORMAL', background: Color(0xFFEFEBF0), foreground: kMuted);
    }
  }
}