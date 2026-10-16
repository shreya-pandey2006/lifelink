import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/blood_request.dart';
import '../../models/potential_donor.dart';
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
  @override
  Widget build(BuildContext context) {
    final p = context.watch<RequestProvider>();
    final shown = p.requests.where((r) => _inFilter(r, _filter)).toList();
    Widget body;
    if (p.loading && p.requests.isEmpty) {
      body = const Center(child: CircularProgressIndicator(color: kPrimary));
    } else if (p.error != null && p.requests.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.error!, textAlign: TextAlign.center),
            TextButton(
                onPressed: () => p.load(), child: const Text('Try again')),
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
            SizedBox(
              width: 240,
              child: PrimaryButton(
                label: 'Request Blood',
                onPressed: () => context.push('/request/new'),
              ),
            ),
          ],
        ),
      );
    } else {
      body = Column(
        children: [
          _filterBar(p.requests),
          Expanded(
            child: RefreshIndicator(
              color: kPrimary,
              onRefresh: () => p.load(silent: true),
              child: shown.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        Center(
                            child: Text('No requests in this filter.',
                                style: TextStyle(color: kMuted))),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: shown.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => RequestCard(
                        shown[i],
                        onTap: () => _showPotentialDonors(shown[i]),
                      ),
                    ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text('My Blood Requests',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/request/new'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Request Blood'),
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

  Widget _filterBar(List<BloodRequest> all) {
    const filters = {
      'all': 'All',
      'open': 'Open',
      'matched': 'Matched',
      'closed': 'Closed',
    };
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.entries.map((e) {
          final count = all.where((r) => _inFilter(r, e.key)).length;
          final selected = _filter == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${e.value} ($count)'),
              selected: selected,
              onSelected: (_) => setState(() => _filter = e.key),
              selectedColor: kPrimarySoft,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? kPrimaryDark : kMuted),
              side: BorderSide(
                  color: selected ? kPrimaryDark : const Color(0xFFEDE7EA)),
              showCheckmark: false,
            ),
          );
        }).toList(),
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
    _future = context.read<RequestProvider>().getPotentialDonors(widget.request.id);
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
                  color: kPrimarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  r.bloodGroup,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kPrimaryDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Details & Donors',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kInk),
                    ),
                    Text(
                      '${r.units} units required in ${r.city}',
                      style: const TextStyle(fontSize: 13, color: kMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEDE7EA)),
          const SizedBox(height: 14),
          const Text(
            'Eligible Matching Donors',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: kInk),
          ),
          const SizedBox(height: 4),
          const Text(
            'Compatible donors in this city who meet donation eligibility criteria.',
            style: TextStyle(fontSize: 12, color: kMuted),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<PotentialDonor>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                final donors = snapshot.data ?? [];
                if (donors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline,
                            size: 48, color: kMuted),
                        const SizedBox(height: 8),
                        const Text(
                          'No matching donors currently available',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Donors in ${r.city} with compatible blood group will appear here as they become available.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: kMuted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: donors.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, idx) {
                    final d = donors[idx];
                    return AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: kPrimarySoft,
                            child: Text(
                              d.bloodGroup,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: kPrimaryDark),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Donor (${d.bloodGroup})',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14),
                                    ),
                                    const Spacer(),
                                    const Pill('READY TO DONATE',
                                        background: Color(0xFFE8F5E9),
                                        foreground: Color(0xFF2E7D32)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${d.city} • Total donations: ${d.totalDonations}',
                                  style: const TextStyle(
                                      fontSize: 12, color: kMuted),
                                ),
                              ],
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
}
