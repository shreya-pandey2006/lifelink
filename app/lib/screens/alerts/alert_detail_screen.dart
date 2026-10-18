import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/alert_provider.dart';
import '../../providers/donor_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/hospital_map.dart';
import '../../widgets/urgency_pill.dart';
import '../../widgets/ui.dart';
class AlertDetailScreen extends StatefulWidget {
  final String requestId;
  const AlertDetailScreen({super.key, required this.requestId});
  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}
class _AlertDetailScreenState extends State<AlertDetailScreen> {
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final alerts = context.read<AlertProvider>();
      if (alerts.alerts.isEmpty) alerts.load();
      final donor = context.read<DonorProvider>();
      if (!donor.loaded) donor.load();
    });
  }
  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);
    final error = await context.read<AlertProvider>().respond(widget.requestId, accept);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? (accept ? 'Thank you! The requester has been notified.' : 'Alert declined.')),
    ));
    if (error == null) context.pop();
  }
  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<AlertProvider>();
    final donor = context.watch<DonorProvider>();
    final matches = alerts.alerts.where((a) => a.requestId == widget.requestId);
    Widget body;
    if (matches.isEmpty) {
      body = alerts.loading ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : Center( child: Padding( padding: const EdgeInsets.all(24),
                child: Column( mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 48, color: kMuted), const SizedBox(height: 12),
                    const Text('This request is no longer available.',
                        style: TextStyle( fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 4), 
                        const Text( 'It may already be covered, or you already responded.',
                        textAlign: TextAlign.center, style: TextStyle(color: kMuted)), const SizedBox(height: 16),
                    TextButton( onPressed: () => context.pop(), child: const Text('Go back')),
                  ],
                ),
              ),
            );
    } else {
      final a = matches.first;
      final km = (donor.hasLocation && a.lat != null && a.lng != null) ? LocationService.distanceKm(donor.lat!, donor.lng!, a.lat!, a.lng!) : null;
      body = ListView( padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AppCard( child: Column( crossAxisAlignment: CrossAxisAlignment.start,
              children: [ Row( children: [ UrgencyPill(a.urgency), const Spacer(),
                    Text(timeAgo(a.createdAt), style: const TextStyle(fontSize: 12, color: kMuted)),
                  ],
                ),
                const SizedBox(height: 14),
                Row( children: [
                    Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                        children: [ Text(a.hospitalName, style: const TextStyle( fontSize: 20, fontWeight: FontWeight.w800, color: kInk)),
                          const SizedBox(height: 4), Text(a.city, style: const TextStyle(color: kMuted)),
                        ],
                      ),
                    ),
                    Container( padding: const EdgeInsets.symmetric( horizontal: 18, vertical: 14),
                      decoration: BoxDecoration( color: kPrimaryDark, borderRadius: BorderRadius.circular(18)),
                      child: Text(a.bloodGroup, style: const TextStyle( fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row( children: [ const Icon(Icons.bloodtype_outlined, size: 18, color: kPrimaryDark), const SizedBox(width: 6),
                    Text( '${a.units} ${a.units == 1 ? 'unit' : 'units'} required',
                        style: const TextStyle(  fontWeight: FontWeight.w700, color: kInk)),
                    if (km != null) ...[
                      const SizedBox(width: 16), const Icon(Icons.near_me_outlined, size: 18, color: kPrimaryDark),
                      const SizedBox(width: 6), Text('${km.toStringAsFixed(1)} km away', style: const TextStyle( fontWeight: FontWeight.w700, color: kInk)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          HospitalMap(
            lat: a.lat,
            lng: a.lng,
            title: a.hospitalName,
            city: a.city,
            height: 200,
          ),
          const SizedBox(height: 14),
          Container( padding: const EdgeInsets.all(12),
            decoration: BoxDecoration( color: const Color(0xFFF1EEF3), borderRadius: BorderRadius.circular(14)),
            child: const Row(
              children: [ Icon(Icons.info_outline, size: 18, color: kMuted), SizedBox(width: 8),
                Expanded( child: Text( 'Accepting tells the requester you are on your way. Please confirm with the hospital before you travel.',
                      style: TextStyle(fontSize: 12.5, color: kMuted)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton( label: 'Accept Request', icon: Icons.check_circle_outline, loading: _busy, onPressed: () => _respond(true) ),
          const SizedBox(height: 10),
          Center( child: TextButton( onPressed: _busy ? null : () => _respond(false),
              child: const Text('Decline', style: TextStyle( color: kMuted, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar( backgroundColor: kBackground, surfaceTintColor: Colors.transparent,
        title: const Text('Request Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: body,
    );
  }
}