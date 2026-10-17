import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/alert_item.dart';
import '../../providers/alert_provider.dart';
import '../../providers/donor_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/alert_card.dart';

class BloodAlertsScreen extends StatefulWidget {
  const BloodAlertsScreen({super.key});

  @override
  State<BloodAlertsScreen> createState() => _BloodAlertsScreenState();
}

class _BloodAlertsScreenState extends State<BloodAlertsScreen> {
  String _filter = 'all';
  String? _busyId;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<AlertProvider>().load();
      context.read<DonorProvider>().load();
    });
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) context.read<AlertProvider>().load(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _inFilter(AlertItem a, String filter) {
    switch (filter) {
      case 'critical':
        return a.urgency == 3;
      case 'urgent':
        return a.urgency == 2;
      default:
        return true;
    }
  }

  double? _distance(AlertItem a, DonorProvider donor) {
    if (!donor.hasLocation || a.lat == null || a.lng == null) return null;
    return LocationService.distanceKm(donor.lat!, donor.lng!, a.lat!, a.lng!);
  }

  Future<void> _respond(AlertItem a, bool accept) async {
    setState(() => _busyId = a.requestId);
    final error = await context.read<AlertProvider>().respond(a.requestId, accept);
    if (!mounted) return;
    setState(() => _busyId = null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ??
          (accept
              ? 'Thank you! The requester has been notified.'
              : 'Alert declined.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<AlertProvider>();
    final donor = context.watch<DonorProvider>();
    final shown = alerts.alerts.where((a) => _inFilter(a, _filter)).toList();

    final children = <Widget>[
      const Text('Blood Donation Alerts',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kInk)),
      const SizedBox(height: 4),
      Row(
        children: [
          const CircleAvatar(radius: 4, backgroundColor: kPrimary),
          const SizedBox(width: 6),
          Text(
              '${alerts.criticalCount} critical \u2022 ${alerts.alerts.length} open \u2022 live radar active',
              style: const TextStyle(fontSize: 13, color: kMuted)),
        ],
      ),
      const SizedBox(height: 14),
      if (!donor.available) ...[
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: kAmberSoft, borderRadius: BorderRadius.circular(14)),
            child: const Row(
              children: [
                Icon(Icons.pause_circle_outline, color: kAmber),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'You are set to unavailable, so new alerts are paused. Tap to change this in your profile.',
                      style: TextStyle(fontSize: 13, color: kInk)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
      _filters(alerts.alerts),
      const SizedBox(height: 14),
    ];

    if (alerts.loading && alerts.alerts.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator(color: kPrimary)),
      ));
    } else if (alerts.error != null && alerts.alerts.isEmpty) {
      children.addAll([
        const SizedBox(height: 40),
        Center(child: Text(alerts.error!, textAlign: TextAlign.center)),
        Center(
          child: TextButton(
              onPressed: () => alerts.load(), child: const Text('Try again')),
        ),
      ]);
    } else if (shown.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 50),
        child: Column(
          children: [
            Icon(Icons.radar, size: 56, color: kMuted),
            SizedBox(height: 12),
            Text('All caught up',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text('No open requests match you right now.',
                style: TextStyle(color: kMuted)),
            Text('You will see new ones here as soon as they are posted.',
                textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
          ],
        ),
      ));
    } else {
      for (final a in shown) {
        children.add(AlertCard(
          alert: a,
          distanceKm: _distance(a, donor),
          busy: _busyId == a.requestId,
          onAccept: () => _respond(a, true),
          onDecline: () => _respond(a, false),
          onTap: () => context.push('/alert/${a.requestId}'),
        ));
        children.add(const SizedBox(height: 14));
      }
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: kPrimary,
          onRefresh: () => alerts.load(silent: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _filters(List<AlertItem> all) {
    const filters = {'all': 'All', 'critical': 'Critical', 'urgent': 'Urgent'};
    return Wrap(
      spacing: 8,
      children: filters.entries.map((e) {
        final count = all.where((a) => _inFilter(a, e.key)).length;
        final selected = _filter == e.key;
        return ChoiceChip(
          label: Text('${e.value} ($count)'),
          selected: selected,
          onSelected: (_) => setState(() => _filter = e.key),
          selectedColor: kPrimaryDark,
          backgroundColor: Colors.white,
          showCheckmark: false,
          labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : kMuted),
          side: BorderSide(
              color: selected ? kPrimaryDark : const Color(0xFFEDE7EA)),
        );
      }).toList(),
    );
  }
}