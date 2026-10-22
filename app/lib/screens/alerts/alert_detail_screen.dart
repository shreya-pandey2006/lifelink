import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/alert_item.dart';
import '../../models/blood_request.dart';
import '../../providers/alert_provider.dart';
import '../../providers/donor_provider.dart';
import '../../services/api_client.dart';
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
  bool _loading = true;
  AlertItem? _alertItem;
  String? _requesterName;
  String? _requesterPhone;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final alerts = context.read<AlertProvider>();
      final initialMatches = alerts.alerts.where((a) => a.requestId == widget.requestId);
      if (initialMatches.isNotEmpty) {
        final match = initialMatches.first;
        setState(() {
          _alertItem = match;
          _requesterName = match.requesterName;
          _requesterPhone = match.requesterPhone;
          _loading = false;
        });
      }
      if (alerts.alerts.isEmpty) alerts.load();
      final donor = context.read<DonorProvider>();
      if (!donor.loaded) donor.load();

      // Fetch request details to load requester phone and coordinator name for the donor
      try {
        final data = await ApiClient.instance.get('/requests/${widget.requestId}');
        final map = asMap(data);
        final reqMap = extractMap(map, ['bloodRequest', 'request']);
        final payload = reqMap.isNotEmpty ? reqMap : map;
        final r = BloodRequest.fromJson(payload);
        final isAvailable = r.status == 'open' || r.status == 'matched';

        if (mounted) {
          if (isAvailable && r.id.isNotEmpty) {
            final item = AlertItem(
              requestId: r.id,
              bloodGroup: r.bloodGroup.isNotEmpty ? r.bloodGroup : 'O+',
              units: r.units > 0 ? r.units : 1,
              hospitalName: r.hospitalName,
              city: r.city,
              urgency: r.urgency,
              status: r.status,
              lat: r.lat,
              lng: r.lng,
              createdAt: r.createdAt,
              department: (r.patient?['healthIssue'] != null &&
                      r.patient!['healthIssue'].toString().trim().isNotEmpty)
                  ? r.patient!['healthIssue'].toString().trim()
                  : (r.urgency == 3
                      ? 'Emergency Blood Request'
                      : 'Blood Request'),
              donorsPinged: 0,
              routeSnippet: '',
              requesterName: r.requesterName,
              requesterPhone: r.requesterPhone,
            );
            setState(() {
              _alertItem = item;
              _requesterName = r.requesterName ?? _requesterName;
              _requesterPhone = r.requesterPhone ?? _requesterPhone;
              _loading = false;
            });
          } else {
            setState(() {
              _alertItem = null;
              _loading = false;
            });
          }
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    });
  }

  Future<void> _respond(bool accept, {String? contactPhone, String? contactName}) async {
    setState(() => _busy = true);
    final error = await context.read<AlertProvider>().respond(widget.requestId, accept);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (!accept) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert declined.')),
      );
      context.pop();
      return;
    }

    final phone = _requesterPhone ?? contactPhone;
    final name = _requesterName ?? contactName ?? 'Requester';

    if (phone != null && phone.trim().isNotEmpty) {
      await showModalBottomSheet(
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
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF059669), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Request Accepted!',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kInk)),
                        Text('Reach out to requester to coordinate',
                            style: TextStyle(fontSize: 12, color: kMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Please reach out to $name before traveling to confirm admission details:',
                style: const TextStyle(fontSize: 13.5, color: kInk, height: 1.3),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E1E6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_in_talk_rounded,
                        color: kPrimaryDark, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        phone.trim(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: kInk,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy requester mobile',
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: phone.trim()));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Requester number copied')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Go to Live Tracking',
                icon: Icons.navigation_rounded,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Color(0xFF059669),
        content: Text('Thank you! Navigating to live tracking...'),
      ));
    }
    if (mounted) {
      context.pushReplacement('/request/${widget.requestId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<AlertProvider>();
    final donor = context.watch<DonorProvider>();
    final matches = alerts.alerts.where((a) => a.requestId == widget.requestId);
    final a = _alertItem ?? (matches.isNotEmpty ? matches.first : null);
    Widget body;
    if (a == null) {
      body = (_loading || alerts.loading)
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 48, color: kMuted),
                    const SizedBox(height: 12),
                    const Text('This request is no longer available.',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text(
                        'It may already be covered, or you already responded.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kMuted)),
                    const SizedBox(height: 16),
                    TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Go back')),
                  ],
                ),
              ),
            );
    } else {
      final km = (donor.hasLocation && a.lat != null && a.lng != null)
          ? LocationService.distanceKm(
              donor.lat!, donor.lng!, a.lat!, a.lng!)
          : null;

      final effectivePhone = _requesterPhone ?? a.requesterPhone;
      final effectiveName = _requesterName ?? a.requesterName ?? 'Requester';

      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UrgencyPill(a.urgency),
                    const Spacer(),
                    Text(timeAgo(a.createdAt),
                        style: const TextStyle(fontSize: 12, color: kMuted)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.hospitalName,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: kInk)),
                          const SizedBox(height: 4),
                          Text(a.city,
                              style: const TextStyle(color: kMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                          color: kPrimaryDark,
                          borderRadius: BorderRadius.circular(18)),
                      child: Text(a.bloodGroup,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.bloodtype_outlined,
                        size: 18, color: kPrimaryDark),
                    const SizedBox(width: 6),
                    Text(
                        '${a.units} ${a.units == 1 ? 'unit' : 'units'} required',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: kInk)),
                    if (km != null) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.near_me_outlined,
                          size: 18, color: kPrimaryDark),
                      const SizedBox(width: 6),
                      Text('${km.toStringAsFixed(1)} km away',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: kInk)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Requester Direct Contact Card (Donor-only privacy feature)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEDE7EA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.phone_in_talk_rounded,
                          size: 20, color: kPrimaryDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Requester Direct Contact',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: kInk,
                            ),
                          ),
                          Text(
                            effectiveName.isNotEmpty
                                ? '$effectiveName (Emergency Contact)'
                                : 'Emergency Blood Requester',
                            style: const TextStyle(
                                fontSize: 12, color: kMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F7FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E1E6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.call, size: 18, color: kPrimaryDark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          (effectivePhone != null &&
                                  effectivePhone.trim().isNotEmpty)
                              ? effectivePhone.trim()
                              : 'Available to matched donor',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: (effectivePhone != null &&
                                    effectivePhone.trim().isNotEmpty)
                                ? kInk
                                : kMuted,
                          ),
                        ),
                      ),
                      if (effectivePhone != null &&
                          effectivePhone.trim().isNotEmpty) ...[
                        IconButton(
                          tooltip: 'Copy requester mobile',
                          icon: const Icon(Icons.copy, size: 18),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: effectivePhone.trim()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Requester number copied')),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined,
                        size: 13, color: kMuted),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Donors can contact requester directly to confirm patient admission details & hospital token.',
                        style: TextStyle(fontSize: 11, color: kMuted),
                      ),
                    ),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFF1EEF3),
                borderRadius: BorderRadius.circular(14)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: kMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Accepting tells the requester you are on your way. Please confirm with the hospital before you travel.',
                      style: TextStyle(fontSize: 12.5, color: kMuted)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Accept Request',
            icon: Icons.check_circle_outline,
            loading: _busy,
            onPressed: () => _respond(
              true,
              contactPhone: effectivePhone,
              contactName: effectiveName,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _busy ? null : () => _respond(false),
              child: const Text('Decline',
                  style: TextStyle(
                      color: kMuted, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text('Request Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: body,
    );
  }
}