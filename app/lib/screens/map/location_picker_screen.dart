import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme.dart';
import '../../services/location_service.dart';
import '../../widgets/ui.dart';

const _cityCenters = {
  'ghaziabad': LatLng(28.6692, 77.4538),
  'noida': LatLng(28.5355, 77.3910),
  'greater noida': LatLng(28.4744, 77.5040),
  'delhi': LatLng(28.6139, 77.2090),
  'new delhi': LatLng(28.6139, 77.2090),
  'gurugram': LatLng(28.4595, 77.0266),
  'faridabad': LatLng(28.4089, 77.3178),
  'meerut': LatLng(28.9845, 77.7064),
  'lucknow': LatLng(26.8467, 80.9462),
  'kanpur': LatLng(26.4499, 80.3319),
  'varanasi': LatLng(25.3176, 82.9739),
  'prayagraj': LatLng(25.4358, 81.8463),
  'patna': LatLng(25.5941, 85.1376),
  'ranchi': LatLng(23.3441, 85.3096),
  'kolkata': LatLng(22.5726, 88.3639),
  'mumbai': LatLng(19.0760, 72.8777),
  'navi mumbai': LatLng(19.0330, 73.0297),
  'pune': LatLng(18.5204, 73.8567),
  'nagpur': LatLng(21.1458, 79.0882),
  'bengaluru': LatLng(12.9716, 77.5946),
  'hyderabad': LatLng(17.3850, 78.4867),
  'chennai': LatLng(13.0827, 80.2707),
  'ahmedabad': LatLng(23.0225, 72.5714),
  'jaipur': LatLng(26.9124, 75.7873),
  'bhopal': LatLng(23.2599, 77.4126),
  'indore': LatLng(22.7196, 75.8577),
  'chandigarh': LatLng(30.7333, 76.7794),
  'dehradun': LatLng(30.3165, 78.0322),
  'bhubaneswar': LatLng(20.2961, 85.8245),
  'kochi': LatLng(9.9312, 76.2673),
  'guwahati': LatLng(26.1445, 91.7362),
};

const _defaultCenter = LatLng(28.6139, 77.2090);

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;
  final String? city;

  const LocationPickerScreen({super.key, this.initial, this.city});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _controller;
  LatLng? _picked;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  LatLng get _start {
    if (widget.initial != null) return widget.initial!;
    final key = widget.city?.trim().toLowerCase();
    if (key != null && _cityCenters.containsKey(key)) {
      return _cityCenters[key]!;
    }
    return _defaultCenter;
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final pos = await LocationService.currentPosition();
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() => _picked = point);
      await _controller?.animateCamera(CameraUpdate.newLatLngZoom(point, 16));
    } on LocationException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not read your location. Try again.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text('Choose hospital location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _start,
              zoom: picked == null ? 12 : 16,
            ),
            onMapCreated: (c) => _controller = c,
            onTap: (point) => setState(() => _picked = point),
            markers: {
              if (picked != null)
                Marker(
                  markerId: const MarkerId('hospital'),
                  position: picked,
                ),
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: kPrimaryDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            picked == null
                                ? 'Tap anywhere on the map to set hospital pin.'
                                : 'Pinned: ${picked.latitude.toStringAsFixed(5)}, ${picked.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, color: kInk),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _locating ? null : _useMyLocation,
                        icon: _locating
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                        label: const Text('Use my current location'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryDark,
                          side: const BorderSide(color: kPrimaryDark),
                          shape: const StadiumBorder(),
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: 'Confirm location',
                      icon: Icons.check,
                      onPressed:
                          picked == null ? null : () => context.pop(picked),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}