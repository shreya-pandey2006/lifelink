import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme.dart';
import '../../services/location_service.dart';
import '../../widgets/ui.dart';
const _cityCenters = {
  'Ghaziabad': LatLng(28.6692, 77.4538), 'Noida': LatLng(28.5355, 77.3910),'Delhi': LatLng(28.6139, 77.2090), 
  'Lucknow': LatLng(26.8467, 80.9462), 'Patna': LatLng(25.5941, 85.1376), 'Mumbai': LatLng(19.0760, 72.8777),
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
  LatLng get _start => widget.initial ?? _cityCenters[widget.city] ?? _defaultCenter;
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
        title: const Text('Choose hospital location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _start, zoom: picked == null ? 12 : 16),
            onMapCreated: (c) => _controller = c, onTap: (point) => setState(() => _picked = point),
            markers: {
              if (picked != null)
                Marker(markerId: const MarkerId('hospital'), position: picked),
            },
            zoomControlsEnabled: false, myLocationButtonEnabled: false, mapToolbarEnabled: false,
          ),
          Positioned(
            left: 16, right: 16, bottom: 16,
            child: SafeArea(
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: kPrimaryDark), const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            picked == null ? 'Tap the map to drop the hospital pin.' : 'Pin: ${picked.latitude.toStringAsFixed(5)}, ${picked.longitude.toStringAsFixed(5)}',
                            style: const TextStyle( fontWeight: FontWeight.w600, color: kInk),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _locating ? null : _useMyLocation,
                        icon: _locating ? const SizedBox( height: 16, width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location),
                        label: const Text('Use my current location'), style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryDark, side: const BorderSide(color: kPrimaryDark), shape: const StadiumBorder(), minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton( label: 'Confirm location', icon: Icons.check,
                      onPressed: picked == null ? null : () => context.pop(picked),
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