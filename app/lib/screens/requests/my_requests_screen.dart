import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/blood_request.dart';
import '../../models/potential_donor.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../widgets/request_card.dart';
import '../../widgets/ui.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  String _filter = 'all';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<RequestProvider>().load();
    });
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) context.read<RequestProvider>().load(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _inFilter(BloodRequest r, String filter) {
    switch (filter) {
      case 'open':
        return r.status == 'open';
      case 'matched':
        return r.status == 'matched';
      case 'closed':
        return r.status == 'fulfilled' ||
            r.status == 'cancelled' ||
            r.status == 'expired';
      default:
        return true;
    }
  }

  void _showHotlineDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded,
                      color: kPrimaryDark, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Dispatch Line',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                      ),
                    ),
                    Text(
                      '24/7 Rapid Emergency Response Coordinator',
                      style: TextStyle(fontSize: 12, color: kMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.health_and_safety_outlined,
                      color: kPrimaryDark, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Toll-Free Dispatch: 1800-LIFE-LINK (+91 800 543 3546)\nDirect Trauma Desk is active.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Close',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showPotentialDonors(BloodRequest req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PotentialDonorsSheet(request: req),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RequestProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final initial = (user?.name != null && user!.name.isNotEmpty)
        ? user.name[0].toUpperCase()
        : '?';

    final shown = p.requests.where((r) => _inFilter(r, _filter)).toList();
    final openCount = p.requests.where((r) => r.status == 'open').length;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FB),
      body: SafeArea(
        child: RefreshIndicator(
          color: kPrimary,
          onRefresh: () => p.load(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =======================================================
                      // 1. Top Header: LifeLink + Brand Logo + Actions
                      // =======================================================
                      Row(
                        children: [
                          const BrandLogo(size: 38),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LifeLink',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: kInk,
                                ),
                              ),
                              Text(
                                'MY BLOOD REQUESTS',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: kPrimaryDark,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Tooltip(
                            message: 'Emergency Hotline',
                            child: Material(
                              color: const Color(0xFFFDE8E8),
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _showHotlineDialog,
                                child: const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.phone_in_talk_rounded,
                                    color: kPrimaryDark,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Tooltip(
                            message: 'View Profile',
                            child: Material(
                              color: kPrimarySoft,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => context.go('/profile'),
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: kPrimaryDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // =======================================================
                      // 2. Title & Live Status Row
                      // =======================================================
                      const Text(
                        'My Blood Requests',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: kInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: openCount > 0
                                  ? const Color(0xFFBA1A1A)
                                  : const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            openCount > 0
                                ? '$openCount Active Urgent Requests \u2022 Live Radar Matching'
                                : 'All requests fulfilled \u2022 Live radar active',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // =======================================================
                      // 3. Filter Chips
                      // =======================================================
                      _buildFilters(p.requests),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ===============================================================
              // 4. Request Cards List or Empty States
              // ===============================================================
              if (p.loading && p.requests.isEmpty) ...[
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  ),
                ),
              ] else if (p.error != null && p.requests.isEmpty) ...[
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p.error!, textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => p.load(),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (p.requests.isEmpty) ...[
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1EEF3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bloodtype_outlined,
                              size: 28, color: kMuted),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No blood requests yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Post an emergency request to dispatch matching donors.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: kMuted),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 200,
                          child: PrimaryButton(
                            label: 'Request Blood',
                            onPressed: () => context.push('/request/new'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (shown.isEmpty) ...[
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'No requests in this filter.',
                        style: TextStyle(fontSize: 13, color: kMuted),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final r = shown[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: RequestCard(
                            r,
                            onTap: () => context.push('/request/${r.id}'),
                            onMatchingDonors: () => _showPotentialDonors(r),
                          ),
                        );
                      },
                      childCount: shown.length,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/request/new'),
        backgroundColor: const Color(0xFFBA1A1A),
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Request Blood',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
        ),
      ),
    );
  }

  Widget _buildFilters(List<BloodRequest> all) {
    final filters = [
      {'key': 'all', 'label': 'All', 'count': all.length},
      {
        'key': 'open',
        'label': 'Open',
        'count': all.where((r) => r.status == 'open').length,
      },
      {
        'key': 'matched',
        'label': 'Matched',
        'count': all.where((r) => r.status == 'matched').length,
      },
      {
        'key': 'closed',
        'label': 'Closed',
        'count': all
            .where((r) =>
                r.status == 'fulfilled' ||
                r.status == 'cancelled' ||
                r.status == 'expired')
            .length,
      },
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final key = f['key'] as String;
          final label = f['label'] as String;
          final count = f['count'] as int;
          final selected = _filter == key;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _filter = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFBA1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFBA1A1A)
                        : const Color(0xFFEDE7EA),
                  ),
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color:
                            const Color(0xFFBA1A1A).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!selected && key == 'open' && count > 0) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      '$label ($count)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : kInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PotentialDonorsSheet extends StatefulWidget {
  final BloodRequest request;
  const _PotentialDonorsSheet({required this.request});

  @override
  State<_PotentialDonorsSheet> createState() => _PotentialDonorsSheetState();
}

class _PotentialDonorsSheetState extends State<_PotentialDonorsSheet> {
  late Future<List<PotentialDonor>> _future;

  @override
  void initState() {
    super.initState();
    _future = context
        .read<RequestProvider>()
        .getPotentialDonors(widget.request.id);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDFDAE0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFCDADA)),
                ),
                child: Text(
                  r.bloodGroup,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFBA1A1A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request Details & Donors',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                      ),
                    ),
                    Text(
                      '${r.hospitalName} \u2022 ${r.city}',
                      style: const TextStyle(fontSize: 12, color: kMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn(
                  'Required',
                  '${r.units} Units',
                  const Color(0xFFBA1A1A),
                ),
                _statColumn(
                  'Fulfilled',
                  '${r.unitsAccepted} Units',
                  const Color(0xFF10B981),
                ),
                _statColumn(
                  'Status',
                  r.status.toUpperCase(),
                  kInk,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Compatible Donors in Radar Range',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: kInk,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<PotentialDonor>>(
              future: _future,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Error loading donors: ${snap.error}',
                      style: const TextStyle(color: kMuted),
                    ),
                  );
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No matching donors currently registered in this city.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kMuted),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final d = list[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEDE7EA)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: kPrimarySoft,
                            child: Text(
                              d.bloodGroup,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: kPrimaryDark,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Donor (${d.bloodGroup}) \u2022 ${d.city}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: kInk,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${d.totalDonations} past donations${d.age != null ? ' \u2022 ${d.age} yrs' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: kMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              d.responseProbability != null
                                  ? '${(d.responseProbability! * 100).toStringAsFixed(0)}% Match'
                                  : 'Matched',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: kMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
