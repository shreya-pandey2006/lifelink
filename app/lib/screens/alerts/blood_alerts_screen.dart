import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/alert_item.dart';
import '../../models/app_user.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/ui.dart';

class BloodAlertsScreen extends StatefulWidget {
  const BloodAlertsScreen({super.key});

  @override
  State<BloodAlertsScreen> createState() => _BloodAlertsScreenState();
}

class _BloodAlertsScreenState extends State<BloodAlertsScreen> {
  String _filter = 'all'; // all, critical, urgent, nearby
  String? _busyId;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final city = auth.user?.city;
      final donorGroup = auth.user?.bloodGroup;
      context.read<AlertProvider>().load(city: city, bloodGroup: donorGroup);
      context.read<DonorProvider>().load();
    });
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      context.read<AlertProvider>().load(
            silent: true,
            city: auth.user?.city,
            bloodGroup: auth.user?.bloodGroup,
          );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _inFilter(AlertItem a, String filter, DonorProvider donor) {
    switch (filter) {
      case 'critical':
        return a.urgency == 3;
      case 'urgent':
        return a.urgency == 2;
      case 'nearby':
        final dist = _distance(a, donor);
        return dist == null || dist <= 15.0;
      default:
        return true;
    }
  }

  double? _distance(AlertItem a, DonorProvider donor) {
    if (!donor.hasLocation || a.lat == null || a.lng == null) return null;
    return LocationService.distanceKm(donor.lat!, donor.lng!, a.lat!, a.lng!);
  }

  Future<void> _respond(AlertItem a, bool accept) async {
    setState(() => _busyId = a.requestId);
    final error =
        await context.read<AlertProvider>().respond(a.requestId, accept);
    if (!mounted) return;
    setState(() => _busyId = null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ??
          (accept
              ? 'Thank you! The hospital and requester have been notified.'
              : 'Alert declined.')),
    ));
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
                    Text('Emergency Dispatch Line',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: kInk)),
                    Text('24/7 Rapid Emergency Response Coordinator',
                        style: TextStyle(fontSize: 12, color: kMuted)),
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
                          color: kInk),
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

  void _triggerSimulator(AuthProvider auth) {
    context.read<AlertProvider>().simulateAlert(
          city: auth.user?.city,
          bloodGroup: auth.user?.bloodGroup,
        );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      backgroundColor: kPrimaryDark,
      content: Row(
        children: [
          Icon(Icons.radar, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Simulated Emergency Blood Request dispatched to your radar!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final alertsProv = context.watch<AlertProvider>();
    final donor = context.watch<DonorProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final shown = alertsProv.alerts
        .where((a) => _inFilter(a, _filter, donor))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: kPrimary,
          onRefresh: () => alertsProv.load(
            silent: true,
            city: user?.city,
            bloodGroup: user?.bloodGroup,
          ),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              // 1. Top Bar Header
              _buildTopHeader(user),
              const SizedBox(height: 14),

              // 2. Standby Crimson Banner
              _buildStandbyBanner(user),
              const SizedBox(height: 16),

              // 3. Screen Title & Status Row
              _buildTitleAndStatus(alertsProv),
              const SizedBox(height: 12),

              // Availability warning if paused
              if (!donor.available) ...[
                GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: kAmberSoft,
                        borderRadius: BorderRadius.circular(14)),
                    child: const Row(
                      children: [
                        Icon(Icons.pause_circle_outline, color: kAmber),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              'You are set to unavailable, so alerts are paused. Tap to change in Profile.',
                              style: TextStyle(fontSize: 12.5, color: kInk)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 4. Filter Chips
              _buildFilters(alertsProv.alerts, donor),
              const SizedBox(height: 16),

              // 5. Alert Cards List
              if (alertsProv.loading && alertsProv.alerts.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                      child: CircularProgressIndicator(color: kPrimary)),
                ),
              ] else if (shown.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEDE7EA)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 44, color: Color(0xFF10B981)),
                      SizedBox(height: 8),
                      Text(
                        'No Emergency Alerts in this Filter',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: kInk),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'All urgent blood requests are currently covered.',
                        style: TextStyle(fontSize: 12.5, color: kMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                for (final a in shown) ...[
                  AlertCard(
                    alert: a,
                    distanceKm: _distance(a, donor),
                    busy: _busyId == a.requestId,
                    onAccept: () => _respond(a, true),
                    onDecline: () => _respond(a, false),
                    onTap: () => context.push('/alert/${a.requestId}'),
                  ),
                  const SizedBox(height: 14),
                ],
              ],



              // 7. Radar Footer Card with Dispatch Simulator
              _buildRadarFooter(auth),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Top Header: LifeLink + BLOOD REQUESTS FEED + Phone Call & Avatar
  // ===========================================================================
  Widget _buildTopHeader(AppUser? user) {
    final initial = (user?.name != null && user!.name.isNotEmpty)
        ? user.name[0].toUpperCase()
        : 'D';

    return Row(
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
              'BLOOD REQUESTS FEED',
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
        // Emergency Call button
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
                width: 42,
                height: 42,
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
        // Donor Profile Avatar
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
                width: 42,
                height: 42,
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
    );
  }

  // ===========================================================================
  // Standby Crimson Banner
  // ===========================================================================
  Widget _buildStandbyBanner(AppUser? user) {
    final group = user?.bloodGroup ?? 'Universal';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B1225), Color(0xFFBA1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B1225).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$group Donor Compatibility Active',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Estimated standby time: 3 mins',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Title & Status Row
  // ===========================================================================
  Widget _buildTitleAndStatus(AlertProvider alertsProv) {
    final critical = alertsProv.criticalCount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Blood Donation Alerts',
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPrimaryDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$critical Urgent Alerts \u2022 Live Radar Active',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: kMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF1EEF3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.tune_rounded, size: 20, color: kInk),
        ),
      ],
    );
  }

  // ===========================================================================
  // Filter Chips (All, Critical, Urgent, Nearby)
  // ===========================================================================
  Widget _buildFilters(List<AlertItem> all, DonorProvider donor) {
    final criticalCount = all.where((a) => a.urgency == 3).length;
    final urgentCount = all.where((a) => a.urgency == 2).length;
    final nearbyCount = all.where((a) {
      final d = _distance(a, donor);
      return d == null || d <= 15.0;
    }).length;

    final chips = [
      {'key': 'all', 'label': 'All (${all.length})'},
      {'key': 'critical', 'label': 'Critical ($criticalCount)', 'dot': true},
      {'key': 'urgent', 'label': 'Urgent ($urgentCount)', 'dot': true, 'color': const Color(0xFFD97706)},
      {'key': 'nearby', 'label': 'Nearby ($nearbyCount)', 'icon': Icons.near_me_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((c) {
          final selected = _filter == c['key'];
          final dotColor = (c['color'] as Color?) ?? kPrimaryDark;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = c['key'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? kPrimaryDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        selected ? kPrimaryDark : const Color(0xFFEDE7EA),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (c['dot'] == true) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? Colors.white : dotColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (c['icon'] != null) ...[
                      Icon(
                        c['icon'] as IconData,
                        size: 13,
                        color: selected ? Colors.white : kInk,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      c['label'] as String,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : kInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }



  // ===========================================================================
  // Radar Footer Card with Dispatch Simulator
  // ===========================================================================
  Widget _buildRadarFooter(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9FB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1EEF3)),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF1EEF3),
            ),
            child: const Icon(Icons.radar, color: kMuted, size: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            'All caught up in your 10km radar.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: kInk,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'We monitor emergency dispatch networks in real-time. You\'ll be notified immediately when a match occurs.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.35, color: kMuted),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => _triggerSimulator(auth),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFF1EEF3),
              foregroundColor: kInk,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Test Dispatch Simulator',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}