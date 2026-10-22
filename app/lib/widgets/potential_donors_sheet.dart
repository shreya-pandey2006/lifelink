import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/blood_request.dart';
import '../models/potential_donor.dart';
import '../providers/request_provider.dart';
import '../providers/tracking_provider.dart';
import '../widgets/ui.dart';

void showPotentialDonorsSheet(BuildContext context, BloodRequest request) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => PotentialDonorsSheet(request: request),
  );
}

class PotentialDonorsSheet extends StatefulWidget {
  final BloodRequest request;
  const PotentialDonorsSheet({super.key, required this.request});

  @override
  State<PotentialDonorsSheet> createState() => _PotentialDonorsSheetState();
}

class _PotentialDonorsSheetState extends State<PotentialDonorsSheet> {
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
          () {
            final Pill pill;
            switch (r.urgency) {
              case 3:
                pill = const Pill('≤ 5 km radius',
                    background: Color(0xFFFEE2E2), foreground: Color(0xFFDC2626));
                break;
              case 2:
                pill = const Pill('≤ 10 km radius',
                    background: Color(0xFFFEF3C7), foreground: Color(0xFFD97706));
                break;
              case 1:
              default:
                pill = const Pill('≤ 20 km radius',
                    background: Color(0xFFE0F2FE), foreground: Color(0xFF0369A1));
                break;
            }
            return Row(
              children: [
                const Text(
                  'Compatible Donors in Radar Range',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kInk,
                  ),
                ),
                const Spacer(),
                pill,
              ],
            );
          }(),
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
                final radius = maxRadiusKmForUrgency(r.urgency);
                final rawList = snap.data ?? [];
                final list = rawList
                    .where((d) => d.distanceKm == null || d.distanceKm! <= radius)
                    .toList();
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No matching donors currently registered within ${radius.toStringAsFixed(0)} km.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kMuted),
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
                                  '${d.name} (${d.bloodGroup}) \u2022 ${d.city}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: kInk,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${d.distanceKm != null ? '${d.distanceKm!.toStringAsFixed(1)} km \u2022 ' : ''}${d.totalDonations} past donations${d.age != null ? ' \u2022 ${d.age} yrs' : ''}',
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
