import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/blood_request.dart';
import 'status_chip.dart';
import 'ui.dart';
class RequestCard extends StatelessWidget {
  final BloodRequest r;
  final VoidCallback? onTap; 
  const RequestCard(this.r, {super.key, this.onTap});
  @override
  Widget build(BuildContext context) {
    final progress = r.units == 0 ? 0.0 : (r.unitsAccepted / r.units).clamp(0.0, 1.0).toDouble();
    return GestureDetector(
      onTap: onTap, child: AppCard(
        child: Column( crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row( children: [
                Container( width: 56, height: 56, alignment: Alignment.center,
                  decoration: BoxDecoration( color: kPrimarySoft, borderRadius: BorderRadius.circular(16)),
                  child: Text(r.bloodGroup, style: const TextStyle( fontSize: 20, fontWeight: FontWeight.w800, color: kPrimaryDark)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column( crossAxisAlignment: CrossAxisAlignment.start,
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
                   child: ClipRRect( borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator( value: progress, minHeight: 6, backgroundColor: const Color(0xFFEFEBF0), color: kPrimaryDark),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${r.unitsAccepted} of ${r.units} units', style: const TextStyle( fontSize: 12, fontWeight: FontWeight.w700, color: kPrimaryDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}