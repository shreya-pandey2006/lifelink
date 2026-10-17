import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/donation.dart';
import '../../providers/history_provider.dart';
import '../../widgets/ui.dart';
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}
class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<HistoryProvider>().load();
    });
  }
  @override
  Widget build(BuildContext context) {
    final p = context.watch<HistoryProvider>();
    Widget body;
    if (p.loading && p.items.isEmpty) {
      body = const Center(child: CircularProgressIndicator(color: kPrimary));
    } else if (p.error != null && p.items.isEmpty) {
      body = Center(
        child: Column( mainAxisSize: MainAxisSize.min,
          children: [ Text(p.error!, textAlign: TextAlign.center), TextButton(onPressed: () => p.load(), child: const Text('Try again')) ],
        ),
      );
    } else if (p.items.isEmpty) {
      body = const Center(
        child: Column( mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop_outlined, size: 56, color: kMuted), SizedBox(height: 12),
            Text('No donations yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text('Requests you accept will appear here.', style: TextStyle(color: kMuted)),
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        color: kPrimary, onRefresh: () => p.load(),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), itemCount: p.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12), itemBuilder: (_, i) => _DonationTile(p.items[i]),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar( backgroundColor: kBackground, surfaceTintColor: Colors.transparent,
        title: const Text('Donation History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
      body: body,
    );
  }
}
class _DonationTile extends StatelessWidget {
  final Donation d;
  const _DonationTile(this.d);
  @override
  Widget build(BuildContext context) {
    final Pill pill;
    switch (d.status) {
      case 'fulfilled': pill = const Pill('COMPLETED', background: Color(0xFFE3F4E8), foreground: Color(0xFF1E7A3C));
      case 'cancelled': pill = const Pill('CANCELLED', background: Color(0xFFEFEBF0), foreground: kMuted);
      default: pill = const Pill('ACCEPTED');
    }
    return AppCard( padding: const EdgeInsets.all(14),
      child: Row( children: [
          Container( width: 54, height: 54, alignment: Alignment.center,
            decoration: BoxDecoration( color: kPrimarySoft, borderRadius: BorderRadius.circular(16)),
            child: Text(d.bloodGroup, style: const TextStyle( fontSize: 18, fontWeight: FontWeight.w800, color: kPrimaryDark)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column( crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.hospitalName, style: const TextStyle( fontSize: 15.5, fontWeight: FontWeight.w800, color: kInk)),
                const SizedBox(height: 2),
                Text( '${d.city} \u2022 ${d.units} ${d.units == 1 ? 'unit' : 'units'} \u2022 ${timeAgo(d.date)}',
                    style: const TextStyle(fontSize: 12, color: kMuted)),
              ],
            ),
          ),
          pill,
        ],
      ),
    );
  }
}