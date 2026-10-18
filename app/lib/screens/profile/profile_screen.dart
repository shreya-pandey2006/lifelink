import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/tracking_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/ui.dart';
import '../../widgets/lifelink_map_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _locating = false;
  bool _sirenAlerts = true;
  bool _pushAlerts = true;
  bool _smsAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
    Future.microtask(() {
      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      if (user != null && user.isDonor) {
        context.read<DonorProvider>().load();
        context.read<HistoryProvider>().load();
      }
    });
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _sirenAlerts = prefs.getBool('pref_siren_alerts') ?? true;
        _pushAlerts = prefs.getBool('pref_push_alerts') ?? true;
        _smsAlerts = prefs.getBool('pref_sms_alerts') ?? true;
      });
    }
  }

  String get _notificationSubtitle {
    final active = <String>[];
    if (_sirenAlerts) active.add('Siren');
    if (_pushAlerts) active.add('Push');
    if (_smsAlerts) active.add('SMS');
    if (active.isEmpty) return 'All dispatch alerts paused';
    return '${active.join(", ")} alerts active';
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _updateLocation() async {
    setState(() => _locating = true);
    try {
      final pos = await LocationService.currentPosition();
      if (!mounted) return;
      final error = await context
          .read<DonorProvider>()
          .updateLocation(pos.latitude, pos.longitude);
      _toast(error ?? 'Your live radar location was updated successfully.');
    } on LocationException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not read your location. Please try again.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _logout() {
    context.read<RequestProvider>().clear();
    context.read<AlertProvider>().clear();
    context.read<DonorProvider>().clear();
    context.read<TrackingProvider>().clear();
    context.read<NotificationProvider>().clear();
    context.read<HistoryProvider>().clear();
    context.read<AuthProvider>().logout();
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

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
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
                        color: const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.notifications_active_outlined,
                          color: kPrimaryDark, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notification & Siren Settings',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: kInk)),
                        Text('Emergency Alert Preferences',
                            style: TextStyle(fontSize: 12, color: kMuted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _settingToggle(
                  title: 'Critical Dispatch Siren',
                  subtitle: 'Bypasses silent mode for urgent blood matches',
                  value: _sirenAlerts,
                  onChanged: (val) {
                    setModalState(() => _sirenAlerts = val);
                    setState(() {});
                  },
                ),
                const Divider(height: 16),
                _settingToggle(
                  title: 'Push Notifications',
                  subtitle: 'Real-time radar alerts for nearby hospitals',
                  value: _pushAlerts,
                  onChanged: (val) {
                    setModalState(() => _pushAlerts = val);
                    setState(() {});
                  },
                ),
                const Divider(height: 16),
                _settingToggle(
                  title: 'SMS & Call Bypass',
                  subtitle: 'Direct SMS relay when trauma team alerts match',
                  value: _smsAlerts,
                  onChanged: (val) {
                    setModalState(() => _smsAlerts = val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Done',
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('pref_siren_alerts', _sirenAlerts);
                    await prefs.setBool('pref_push_alerts', _pushAlerts);
                    await prefs.setBool('pref_sms_alerts', _smsAlerts);
                    _toast('Notification preferences saved.');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _settingToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 11.5, color: kMuted)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: kPrimaryDark,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showPrivacyTerms() {
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
                    color: const Color(0xFFF1EEF3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: kInk, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Privacy & Medical Terms',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: kInk)),
                    Text('HIPAA & Data Protection Standards',
                        style: TextStyle(fontSize: 12, color: kMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '• Encrypted Records: All donor medical screening forms and blood group records are secured with AES-256 encryption.\n\n'
              '• Geolocation Privacy: Your GPS location is exclusively utilized to compute emergency radar radius matching.\n\n'
              '• Consent Ledger: Blood donation records are maintained for audit trails with participating hospitals.',
              style: TextStyle(fontSize: 13, height: 1.4, color: kInk),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Understood',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showHospitalNetwork(BuildContext context, String city) {
    final cityName = city.trim().isNotEmpty ? city.trim() : 'Your City';
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
                    color: const Color(0xFFFDE8E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.apartment_rounded,
                      color: kPrimaryDark, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$cityName Trauma & Blood Bank Network',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: kInk,
                        ),
                      ),
                      const Text(
                        'Accredited Government & Private Blood Banks',
                        style: TextStyle(fontSize: 11.5, color: kMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.emergency_outlined,
                          color: kPrimaryDark, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'National Blood Transfusion Grid: 1910',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kInk),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.local_hospital_outlined,
                          color: Color(0xFF065F46), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Emergency Trauma Ambulance: 108 / 112',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kInk),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          color: Color(0xFF3730A3), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'District Red Cross Blood Center: Verified 24/7',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kInk),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Close Directory',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requesterStatBox({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requesterHubCard(
      BuildContext context, RequestProvider reqProv, AppUser user) {
    final activeCount = reqProv.requests
        .where((r) => r.status == 'open' || r.status == 'matched')
        .length;
    final fulfilledCount = reqProv.requests
        .where((r) => r.status == 'fulfilled')
        .length;
    final totalCount = reqProv.requests.length;

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_hospital_rounded,
                    color: Color(0xFFBA1A1A), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Request Hub',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                      ),
                    ),
                    Text(
                      user.city.isNotEmpty
                          ? 'Broadcasting across ${user.city} network'
                          : 'Live triage & donor dispatch desk',
                      style: const TextStyle(fontSize: 11.5, color: kMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: activeCount > 0
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activeCount > 0 ? '$activeCount Active' : 'Standby',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: activeCount > 0
                        ? const Color(0xFFB45309)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _requesterStatBox(
                  label: 'Active',
                  value: '$activeCount',
                  color: const Color(0xFFBA1A1A),
                  bgColor: const Color(0xFFFDF2F2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _requesterStatBox(
                  label: 'Fulfilled',
                  value: '$fulfilledCount',
                  color: const Color(0xFF065F46),
                  bgColor: const Color(0xFFD1FAE5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _requesterStatBox(
                  label: 'Total',
                  value: '$totalCount',
                  color: kInk,
                  bgColor: const Color(0xFFF8F7FA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/create-request'),
              icon: const Icon(Icons.add_circle_outline, size: 19),
              label: const Text(
                'Request Blood Now',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _donorRadarCard(DonorProvider donor, AppUser user) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: donor.available
                      ? const Color(0xFF10B981)
                      : const Color(0xFFBA1A1A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available to Donate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                      ),
                    ),
                    Text(
                      donor.available
                          ? 'Live Dispatch Ready'
                          : 'Alerts are paused',
                      style: const TextStyle(fontSize: 12, color: kMuted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: donor.available,
                activeThumbColor: const Color(0xFFBA1A1A),
                onChanged: (val) async {
                  final err =
                      await context.read<DonorProvider>().setAvailable(val);
                  if (err != null) _toast(err);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.radar,
                        color: Color(0xFFBA1A1A), size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Current dispatch radius',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kInk,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE7EA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '10 KM',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: kInk,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Within 10 km \u2022 Real-time GPS enabled',
                    style: TextStyle(fontSize: 11.5, color: kMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _donorMap(donor, user),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _locating ? null : _updateLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: Text(
                _locating
                    ? 'Updating Radar...'
                    : 'Update Live Location / Radar',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _donorMap(DonorProvider donor, AppUser user) {
    final double lat;
    final double lng;
    final bool isLiveGps;
    final String label;

    if (donor.hasLocation) {
      lat = donor.lat!;
      lng = donor.lng!;
      isLiveGps = true;
      label =
          'Live Location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    } else {
      final cityCoords = getCoordinatesForCity(user.city);
      lat = cityCoords?.$1 ?? 28.6692;
      lng = cityCoords?.$2 ?? 77.4538;
      isLiveGps = false;
      label = user.city.trim().isNotEmpty
          ? '${user.city} (Registered City Location)'
          : 'Approximate City Location';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LifeLinkMapView(
          key: ValueKey('$lat,$lng,$isLiveGps'),
          latitude: lat,
          longitude: lng,
          zoom: isLiveGps ? 14 : 12.5,
          height: 165,
          isLiveGps: isLiveGps,
          showRadarRings: true,
          radarRadiusKm: 10.0,
          badgeText: isLiveGps ? 'GPS Active' : 'City Center',
          badgeIcon: isLiveGps ? Icons.gps_fixed : Icons.location_city,
          badgeColor: isLiveGps ? const Color(0xFF10B981) : kPrimaryDark,
          markerTitle:
              isLiveGps ? 'Your Live Location' : '${user.city} Location',
          markerSubtitle: isLiveGps ? 'GPS Verified' : 'Registered City',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              isLiveGps ? Icons.check_circle : Icons.info_outline,
              size: 15,
              color: isLiveGps ? const Color(0xFF10B981) : kMuted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isLiveGps ? FontWeight.w700 : FontWeight.w600,
                  color: isLiveGps ? const Color(0xFF065F46) : kMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final donor = context.watch<DonorProvider>();
    final history = context.watch<HistoryProvider>();
    final reqProv = context.watch<RequestProvider>();

    if (user == null) return const SizedBox.shrink();

    final group = user.bloodGroup;
    final initial = user.name.isEmpty ? '?' : user.name[0].toUpperCase();

    final activeReqCount = reqProv.requests
        .where((r) => r.status == 'open' || r.status == 'matched')
        .length;
    final pastReqCount = reqProv.requests
        .where((r) => r.status == 'fulfilled' || r.status == 'cancelled')
        .length;

    final int donationCount = donor.totalDonations > history.items.length
        ? donor.totalDonations
        : history.items.length;
    final livesImpacted = donationCount * 3;
    final String donationSubtitle = donationCount > 0
        ? '$donationCount Lifesaving Donation${donationCount == 1 ? '' : 's'} \u2022 $livesImpacted Lives Impacted'
        : '0 Lifesaving Donations \u2022 0 Lives Impacted';
    final String? tierBadge = donationCount >= 10
        ? 'Platinum Donor Tier'
        : donationCount >= 5
            ? 'Gold Donor Tier'
            : donationCount >= 1
                ? 'Silver Donor Tier'
                : null;
    final Color tierBadgeColor = donationCount >= 10
        ? const Color(0xFFE0E7FF)
        : donationCount >= 5
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFF1F5F9);
    final Color tierBadgeTextColor = donationCount >= 10
        ? const Color(0xFF3730A3)
        : donationCount >= 5
            ? const Color(0xFFB45309)
            : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
          children: [
            // =================================================================
            // Top App Bar Header: LifeLink + DONOR PROFILE + Call & Avatar
            // =================================================================
            Row(
              children: [
                const BrandLogo(size: 38),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LifeLink',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: kInk,
                      ),
                    ),
                    Text(
                      user.isDonor ? 'DONOR PROFILE' : 'REQUESTER PROFILE',
                      style: const TextStyle(
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kPrimarySoft,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kPrimaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // =================================================================
            // Profile Header Card (Common user card with role-specific badge)
            // =================================================================
            Container(
              padding: const EdgeInsets.all(18),
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
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar with verified checkmark badge
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: kPrimarySoft,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: kPrimaryDark,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name.isNotEmpty
                                  ? user.name
                                  : 'LifeLink Member',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: kInk,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: const TextStyle(
                                  fontSize: 13, color: kMuted),
                            ),
                            if (user.phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                user.phone,
                                style: const TextStyle(
                                    fontSize: 13, color: kMuted),
                              ),
                            ],
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: kPrimaryDark,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    user.city.isNotEmpty
                                        ? '${user.city} (Metro Area)'
                                        : 'Location Not Set',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: kInk,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Role & Availability Badges Row
                  Row(
                    children: [
                      // Badge 1: Real Role badge
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFCDADA)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                user.isDonor
                                    ? Icons.water_drop
                                    : Icons.local_hospital,
                                color: const Color(0xFF8B1225),
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  user.isDonor
                                      ? 'Verified Blood Donor'
                                      : 'Registered Requester',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF8B1225),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (user.isDonor) ...[
                        const SizedBox(width: 8),
                        // Badge 2: Live Radar Availability badge (DONOR ONLY)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: donor.available
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: donor.available
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  donor.available
                                      ? Icons.radar
                                      : Icons.pause_circle_outline,
                                  color: donor.available
                                      ? const Color(0xFF065F46)
                                      : const Color(0xFF4B5563),
                                  size: 13,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    donor.available
                                        ? 'Live Radar Active'
                                        : 'Alerts Paused',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: donor.available
                                          ? const Color(0xFF065F46)
                                          : const Color(0xFF4B5563),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Blood Group Container (if available)
                  if (group != null && group.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFCDADA)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFBA1A1A),
                            ),
                            child: const Icon(Icons.favorite,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.isDonor
                                      ? 'BLOOD GROUP TYPE'
                                      : 'PATIENT / REQUESTER BLOOD GROUP',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: Color(0xFF8B1225),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.isDonor
                                      ? (group == 'O-'
                                          ? 'O- (Universal Donor)'
                                          : '$group (${kDonatesTo[group]?.contains('AB+') ?? false ? 'Compatible Match' : 'Universal Match'})')
                                      : '$group (Recipient Profile)',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: kInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B1225),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.isDonor
                                  ? ((group == 'O-' || group == 'O+')
                                      ? 'UNIVERSAL'
                                      : (donor.available ? 'RADAR ACTIVE' : 'STANDBY'))
                                  : 'REGISTERED',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // =================================================================
            // Role-Specific Center Card:
            // Donor sees Live Radar Dispatch Card;
            // Requester sees Emergency Request Hub Card.
            // =================================================================
            if (user.isDonor) ...[
              _donorRadarCard(donor, user),
            ] else ...[
              _requesterHubCard(context, reqProv, user),
            ],
            const SizedBox(height: 16),

            // =================================================================
            // Role-Specific & Common Menu Cards
            // =================================================================
            if (user.isDonor) ...[
              // 1. Donation History & Impact (DONOR ONLY)
              _ProfileMenuCard(
                icon: Icons.water_drop_outlined,
                iconBgColor: const Color(0xFFFDE8E8),
                iconColor: const Color(0xFFBA1A1A),
                title: 'Donation History & Impact',
                badgeText: tierBadge,
                badgeColor: tierBadgeColor,
                badgeTextColor: tierBadgeTextColor,
                subtitle: donationSubtitle,
                onTap: () => context.push('/history'),
              ),
              const SizedBox(height: 12),

              // 2. Medical Eligibility & Screening Form (DONOR ONLY)
              _ProfileMenuCard(
                icon: Icons.assignment_turned_in_outlined,
                iconBgColor: const Color(0xFFF1EEF3),
                iconColor: const Color(0xFF8B1225),
                title: 'Medical Eligibility & Screening Form',
                badgeText: donor.hasHealthDetails ? 'Verified' : 'Pending',
                badgeColor: donor.hasHealthDetails
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFFEE2E2),
                badgeTextColor: donor.hasHealthDetails
                    ? const Color(0xFF065F46)
                    : const Color(0xFF991B1B),
                subtitle: donor.hasHealthDetails
                    ? 'Health details recorded (${donor.age ?? "-"} yrs, ${donor.weight != null ? donor.weight!.toStringAsFixed(0) : "-"} kg, Hb ${donor.hemoglobin ?? "-"} g/dL)'
                    : 'Screening not completed yet \u2022 Tap to fill form',
                onTap: () => context.push('/donor-details'),
              ),
              const SizedBox(height: 12),
            ] else ...[
              // 1. My Emergency Blood Requests (REQUESTER ONLY)
              _ProfileMenuCard(
                icon: Icons.medical_services_outlined,
                iconBgColor: const Color(0xFFFDE8E8),
                iconColor: const Color(0xFFBA1A1A),
                title: 'My Emergency Blood Requests',
                subtitle:
                    '$activeReqCount Active Request \u2022 $pastReqCount Past Requests',
                onTap: () => context.go('/requests'),
              ),
              const SizedBox(height: 12),

              // 2. Hospital & Blood Bank Network (REQUESTER ONLY)
              _ProfileMenuCard(
                icon: Icons.apartment_rounded,
                iconBgColor: const Color(0xFFF1EEF3),
                iconColor: const Color(0xFF8B1225),
                title: 'Hospital & Blood Bank Directory',
                subtitle: user.city.isNotEmpty
                    ? 'Accredited trauma centers & blood banks in ${user.city}'
                    : 'Accredited trauma centers & blood bank network',
                onTap: () => _showHospitalNetwork(context, user.city),
              ),
              const SizedBox(height: 12),

              // 3. Register as Volunteer Blood Donor (REQUESTER ONLY)
              _ProfileMenuCard(
                icon: Icons.volunteer_activism_outlined,
                iconBgColor: const Color(0xFFFDF2F2),
                iconColor: const Color(0xFFBA1A1A),
                title: 'Register as Blood Donor',
                badgeText: 'Optional',
                badgeColor: const Color(0xFFE0E7FF),
                badgeTextColor: const Color(0xFF3730A3),
                subtitle: 'Join live radar to donate blood and save lives',
                onTap: () => context.push('/donor-details'),
              ),
              const SizedBox(height: 12),
            ],

            // COMMON: Notification & Siren Settings
            _ProfileMenuCard(
              icon: Icons.notifications_active_outlined,
              iconBgColor: const Color(0xFFF1EEF3),
              iconColor: kInk,
              title: 'Notification & Siren Settings',
              badgeText: (_sirenAlerts && _pushAlerts && _smsAlerts)
                  ? 'All Active'
                  : (_sirenAlerts || _pushAlerts || _smsAlerts)
                      ? 'Custom'
                      : 'Muted',
              badgeColor: (_sirenAlerts && _pushAlerts && _smsAlerts)
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFFEF3C7),
              badgeTextColor: (_sirenAlerts && _pushAlerts && _smsAlerts)
                  ? const Color(0xFF065F46)
                  : const Color(0xFFB45309),
              subtitle: _notificationSubtitle,
              onTap: _showNotificationSettings,
            ),
            const SizedBox(height: 12),

            // COMMON: Privacy, Security & Medical Terms
            _ProfileMenuCard(
              icon: Icons.shield_outlined,
              iconBgColor: const Color(0xFFF1EEF3),
              iconColor: kInk,
              title: 'Privacy, Security & Medical Terms',
              subtitle: 'Encrypted records, consent ledger & audit logs',
              onTap: _showPrivacyTerms,
            ),
            const SizedBox(height: 22),

            // =================================================================
            // COMMON: Log Out Button & Role-Specific Warning
            // =================================================================
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                'Log Out of LifeLink',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFBA1A1A),
                backgroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
                side: const BorderSide(color: Color(0xFFEDE7EA)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 16, color: Color(0xFFBA1A1A)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    user.isDonor
                        ? 'Logging out pauses live emergency dispatch alerts in your radius.'
                        : 'Logging out will sign you out of your emergency request desk.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11.5, color: kMuted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final VoidCallback onTap;

  const _ProfileMenuCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE7EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 21),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: kInk,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor ?? const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badgeText!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: badgeTextColor ??
                                      const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: kMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: kMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}