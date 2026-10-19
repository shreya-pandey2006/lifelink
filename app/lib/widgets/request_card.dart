import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/blood_request.dart';
import 'status_chip.dart';

class RequestCard extends StatelessWidget {
  final BloodRequest r;
  final VoidCallback? onTap;
  final VoidCallback? onMatchingDonors;

  const RequestCard(this.r, {super.key, this.onTap, this.onMatchingDonors});

  @override
  Widget build(BuildContext context) {
    final progress = r.units == 0
        ? 0.0
        : (r.unitsAccepted / r.units).clamp(0.0, 1.0).toDouble();

    final VoidCallback? effectiveTap = onTap ??
        (r.id.isNotEmpty ? () => context.push('/request/${r.id}') : null);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE7EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: effectiveTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFCDADA)),
                      ),
                      child: Text(
                        r.bloodGroup,
                        style: const TextStyle(
                          fontSize: 17,
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
                          Text(
                            r.hospitalName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: kInk,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${r.city} \u2022 ${kUrgencyLabels[r.urgency] ?? 'Urgent'}${r.predictedUrgency != null ? ' (AI: ${r.predictedUrgency})' : ''} \u2022 ${timeAgo(r.createdAt)}',
                            style:
                                const TextStyle(fontSize: 12, color: kMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(r.status),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFEFEBF0),
                          color: const Color(0xFFBA1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${r.unitsAccepted} of ${r.units} units',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFBA1A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF5F3F6)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: effectiveTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                r.status == 'open'
                                    ? 'Track Request Live'
                                    : 'View Details',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: kPrimaryDark,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 14, color: kPrimaryDark),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (onMatchingDonors != null &&
                        (r.status == 'open' || r.status == 'matched'))
                      Material(
                        color: const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onMatchingDonors,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.people_alt_outlined,
                                    size: 14, color: Color(0xFF8B1225)),
                                SizedBox(width: 5),
                                Text(
                                  'Matching Donors',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF8B1225),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}