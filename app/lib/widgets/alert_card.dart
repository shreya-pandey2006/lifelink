import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/alert_item.dart';
import 'urgency_pill.dart';
class AlertCard extends StatelessWidget {
  final AlertItem alert;
  final double? distanceKm;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTap;
  const AlertCard({
    super.key,
    required this.alert,
    required this.distanceKm,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final accent = alert.urgency == 3 ? kPrimaryDark : (alert.urgency == 2 ? kAmber : kMuted);
    final soft = alert.urgency == 3 ? kPrimarySoft : (alert.urgency == 2 ? kAmberSoft : const Color(0xFFEFEBF0));
    return GestureDetector(
      onTap: onTap, child: Container(
        clipBehavior: Clip.antiAlias, decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: const [  BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 5)), ],
        ),
        child: IntrinsicHeight(
          child: Row( crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [ Container(width: 5, color: accent),
              Expanded( child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row( children: [
                          UrgencyPill(alert.urgency), const Spacer(),
                           Text(timeAgo(alert.createdAt), style: const TextStyle(fontSize: 12, color: kMuted)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row( children: [ Expanded(
                            child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                              children: [ 
                                Text(alert.hospitalName, style: const TextStyle( fontSize: 17, fontWeight: FontWeight.w800, color: kInk)),
                                const SizedBox(height: 2),
                                Row( children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: kMuted), const SizedBox(width: 2),
                                    Text(alert.city, style: const TextStyle( fontSize: 13, color: kMuted)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container( padding: const EdgeInsets.symmetric( horizontal: 14, vertical: 10),
                            decoration: BoxDecoration( color: soft, borderRadius: BorderRadius.circular(14)),
                            child: Text(alert.bloodGroup, style: TextStyle( fontSize: 20, fontWeight: FontWeight.w800, color: accent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container( padding: const EdgeInsets.symmetric( horizontal: 12, vertical: 10),
                        decoration: BoxDecoration( color: const Color(0xFFF4F1F6), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Text('${alert.units} ${alert.units == 1 ? 'unit' : 'units'} required', 
                            style: const TextStyle( fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
                            const Spacer(),
                            if (distanceKm != null) ...[
                              const Icon(Icons.near_me_outlined, size: 14, color: kPrimaryDark),
                              const SizedBox(width: 4),
                              Text('${distanceKm!.toStringAsFixed(1)} km away', 
                              style: const TextStyle( fontSize: 13, fontWeight: FontWeight.w700, color: kPrimaryDark)),
                            ] else
                              const Text('Tap for details', style: TextStyle(fontSize: 12, color: kMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded( child: FilledButton.icon(
                              onPressed: busy ? null : onAccept, style: FilledButton.styleFrom( backgroundColor: kPrimaryDark, minimumSize: const Size.fromHeight(46), shape: const StadiumBorder() ),
                              icon: busy ? const SizedBox( height: 16, width: 16,
                                      child: CircularProgressIndicator( strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.check_circle_outline, size: 18), label: const Text('Accept'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded( child: OutlinedButton( onPressed: busy ? null : onDecline,
                              style: OutlinedButton.styleFrom( foregroundColor: kMuted, minimumSize: const Size.fromHeight(46), shape: const StadiumBorder() ),
                              child: const Text('Decline'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}