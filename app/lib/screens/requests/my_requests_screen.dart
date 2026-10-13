import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/blood_request.dart';
import '../../providers/request_provider.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/ui.dart';
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});
  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}
class _MyRequestsScreenState extends State<MyRequestsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<RequestProvider>().load();
    });
  }
  @override
  Widget build(BuildContext context) {
    final p = context.watch<RequestProvider>();
    Widget body;
    if (p.loading && p.requests.isEmpty) {
      body = const Center(child: CircularProgressIndicator(color: kPrimary));
    } else if (p.error != null && p.requests.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.error!, textAlign: TextAlign.center),
            TextButton( onPressed: () => p.load(), child: const Text('Try again')),
          ],
        ),
      );
    } else if (p.requests.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bloodtype_outlined, size: 56, color: kMuted),
            const SizedBox(height: 12),
            const Text('No requests yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Post an urgent request to alert matching donors.',
                style: TextStyle(color: kMuted)),
            const SizedBox(height: 20),
            SizedBox( width: 240, child: PrimaryButton( label: 'Request Blood', onPressed: () => context.push('/request/new') ) ),
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        color: kPrimary, onRefresh: () => p.load(silent: true),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), itemCount: p.requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14), itemBuilder: (_, i) => _RequestCard(p.requests[i]),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar( backgroundColor: kBackground, surfaceTintColor: Colors.transparent,
        title: const Text('My Blood Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ),
      body: body, floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/request/new'),
        backgroundColor: kPrimary, foregroundColor: Colors.white, icon: const Icon(Icons.add), label: const Text('Request Blood'),
      ),
    );
  }
}
class _RequestCard extends StatelessWidget {
  final BloodRequest r;
  const _RequestCard(this.r);
  @override
  Widget build(BuildContext context) {
    final progress = r.units == 0 ? 0.0 : r.unitsAccepted / r.units;
    return AppCard(
      child: Column( crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container( width: 56, height: 56, alignment: Alignment.center, 
              decoration: BoxDecoration( color: kPrimarySoft, borderRadius: BorderRadius.circular(16)),
                child: Text(r.bloodGroup,
                    style: const TextStyle( fontSize: 20, fontWeight: FontWeight.w800, color: kPrimaryDark)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.hospitalName, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle( fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
                    const SizedBox(height: 2),
                    Text( '${r.city} \u2022 ${kUrgencyLabels[r.urgency] ?? 'Urgent'} \u2022 ${timeAgo(r.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: kMuted)),
                  ],
                ),
              ),
              StatusChip(r.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator( value: progress, minHeight: 6, backgroundColor: const Color(0xFFEFEBF0), color: kPrimaryDark ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${r.unitsAccepted} of ${r.units} units', style: const TextStyle( fontSize: 12, fontWeight: FontWeight.w700, color: kPrimaryDark)),
            ],
          ),
        ],
      ),
    );
  }
}
