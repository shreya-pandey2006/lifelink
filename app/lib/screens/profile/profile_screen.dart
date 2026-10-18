import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
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
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  bool _locating = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      if (user != null && user.isDonor) context.read<DonorProvider>().load();
    });
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
      _toast(error ?? 'Your location was updated.');
    } on LocationException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not read your location. Try again.');
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

  Widget _donorMap(DonorProvider donor, AppUser user) {
    final double lat;
    final double lng;
    final bool isLiveGps;
    final String label;

    if (donor.hasLocation) {
      lat = donor.lat!;
      lng = donor.lng!;
      isLiveGps = true;
      label = 'Live Location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    } else {
      final cityCoords = getCoordinatesForCity(user.city);
      lat = cityCoords?.$1 ?? 28.6692;
      lng = cityCoords?.$2 ?? 77.4538;
      isLiveGps = false;
      label = user.city.trim().isNotEmpty
          ? '${user.city} (Registered City Location)'
          : 'Approximate City Location';
    }

    final point = LatLng(lat, lng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 155,
            width: double.infinity,
            child: Stack(
              children: [
                GoogleMap(
                  key: ValueKey('$lat,$lng,$isLiveGps'),
                  initialCameraPosition: CameraPosition(
                    target: point,
                    zoom: isLiveGps ? 15 : 12,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('donor_pin'),
                      position: point,
                      infoWindow: InfoWindow(
                        title: isLiveGps ? 'Your Live Location' : '${user.city} Location',
                        snippet: isLiveGps ? 'GPS Verified' : 'Registered City',
                      ),
                    ),
                  },
                  liteModeEnabled: true,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiveGps ? Icons.gps_fixed : Icons.location_city,
                          size: 13,
                          color: isLiveGps ? const Color(0xFF2E7D32) : kPrimaryDark,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isLiveGps ? 'GPS Active' : 'City Center',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isLiveGps ? const Color(0xFF2E7D32) : kPrimaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              isLiveGps ? Icons.check_circle : Icons.info_outline,
              size: 15,
              color: isLiveGps ? const Color(0xFF2E7D32) : kMuted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isLiveGps ? FontWeight.w700 : FontWeight.w600,
                  color: isLiveGps ? const Color(0xFF2E7D32) : kMuted,
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
    if (user == null) return const SizedBox.shrink();
    final group = user.bloodGroup;
    return Scaffold(
      body: SafeArea( child: ListView( padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [ AppCard(
              child: Column( children: [ CircleAvatar( radius: 38, backgroundColor: kPrimarySoft,
                    child: Text( user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                        style: const TextStyle( fontSize: 30, fontWeight: FontWeight.w800, color: kPrimaryDark)),
                  ),
                  const SizedBox(height: 12),
                  Text(user.name, style: const TextStyle( fontSize: 22, fontWeight: FontWeight.w800, color: kInk)), const SizedBox(height: 4),
                  Text(user.email, style: const TextStyle(color: kMuted)),
                  Text(user.phone, style: const TextStyle(color: kMuted)), const SizedBox(height: 4),
                  Row( mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: kPrimaryDark), const SizedBox(width: 2),
                      Text(user.city, style: const TextStyle( color: kInk, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12), Pill(user.isDonor ? 'BLOOD DONOR' : 'BLOOD REQUESTER'),
                ],
              ),
            ),
            if (user.isDonor && group != null) ...[
              const SizedBox(height: 14),
              Container( padding: const EdgeInsets.all(16),
                decoration: BoxDecoration( color: kPrimarySoft, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [ const CircleAvatar( radius: 22, backgroundColor: Colors.white, child: Icon(Icons.favorite, color: kPrimaryDark),
                    ),
                    const SizedBox(width: 14),
                    Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BLOOD GROUP TYPE', style: TextStyle( fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w800, color: kMuted)),
                          Text(group == 'O-' ? 'O- (Universal Donor)' : group, style: const TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.w800, color: kInk)),
                          Text('Can donate to: ${kDonatesTo[group]?.join(', ') ?? '-'}',
                              style: const TextStyle( fontSize: 12, color: kPrimaryDark)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                  children: [ Row(
                      children: [ Expanded(
                          child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Available to Donate', style: TextStyle( fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
                              const SizedBox(height: 2),
                              Text( donor.available ? 'Alerts for your city are on' : 'Alerts are paused',
                                  style: const TextStyle( fontSize: 13, color: kMuted)),
                            ],
                          ),
                        ),
                        Switch( value: donor.available, onChanged: (value) async {
                            final error = await context
                                .read<DonorProvider>()
                                .setAvailable(value);
                            if (error != null) _toast(error);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _donorMap(donor, user),
                    const SizedBox(height: 14),
                    PrimaryButton( label: 'Update Live Location', icon: Icons.gps_fixed, loading: _locating, onPressed: _updateLocation ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (user.isDonor) ...[
              _MenuTile( icon: Icons.monitor_heart_outlined, title: 'Donor Health Details', subtitle: donor.hasHealthDetails
                    ? 'Saved. Used by the ML ranking.' : 'Not filled yet. Used by the ML ranking.',
                onTap: () => context.push('/donor-details'),
              ),
              const SizedBox(height: 10),
              _MenuTile( icon: Icons.water_drop_outlined, title: 'Donation History', subtitle: 'Requests you accepted',
                onTap: () => context.push('/history'),
              ),
            ] else
              _MenuTile( icon: Icons.local_hospital_outlined, title: 'My Emergency Blood Requests', subtitle: 'Open, matched and closed requests',
                onTap: () => context.go('/requests'),
              ),
            const SizedBox(height: 10),
            _MenuTile( icon: Icons.notifications_outlined, title: 'Notifications', subtitle: 'Alerts and request updates',
              onTap: () => context.go('/alerts'),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon( onPressed: _logout,
              icon: const Icon(Icons.logout), label: const Text('Log Out of LifeLink'),
              style: OutlinedButton.styleFrom( foregroundColor: kPrimaryDark, minimumSize: const Size.fromHeight(52), shape: const StadiumBorder(),
                side: const BorderSide(color: Color(0xFFEDE7EA)), backgroundColor: Colors.white,
              ),
            ),
            if (user.isDonor) ...[ const SizedBox(height: 10), const Text('Logging out pauses emergency alerts on this phone.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: kMuted)) ],
          ],
        ),
      ),
    );
  }
}
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuTile({ required this.icon, required this.title, required this.subtitle, required this.onTap });
  @override
  Widget build(BuildContext context) {
    return GestureDetector( onTap: onTap,
      child: AppCard( padding: const EdgeInsets.all(14),
        child: Row(
          children: [ CircleAvatar( radius: 22, backgroundColor: kPrimarySoft, child: Icon(icon, color: kPrimaryDark, size: 22) ),
            const SizedBox(width: 14),
            Expanded(
              child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,  style: const TextStyle( fontSize: 15.5, fontWeight: FontWeight.w800, color: kInk)), const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12.5, color: kMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kMuted),
          ],
        ),
      ),
    );
  }
}