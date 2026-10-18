import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../core/theme.dart';
import 'lifelink_map_view.dart';

class LocationCard extends StatelessWidget {
  final LatLng? pin;
  final bool busy;
  final VoidCallback onChooseOnMap;
  final VoidCallback onUseGps;

  const LocationCard({
    super.key,
    required this.pin,
    required this.busy,
    required this.onChooseOnMap,
    required this.onUseGps,
  });

  @override
  Widget build(BuildContext context) {
    final p = pin;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p != null)
            LifeLinkMapView(
              key: ValueKey('${p.latitude},${p.longitude}'),
              latitude: p.latitude,
              longitude: p.longitude,
              zoom: 15,
              height: 150,
              showRadarRings: false,
              interactive: false,
              showControls: false,
              markerTitle: 'Hospital Pin',
              markerSubtitle:
                  '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}',
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: kPrimaryDark, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p == null
                            ? 'No location set. Pin the hospital so donors can see how far it is.'
                            : 'Pinned: ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 12.5, color: kInk),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onChooseOnMap,
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: Text(p == null ? 'Choose on map' : 'Edit pin'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryDark,
                          side: const BorderSide(color: kPrimaryDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: busy ? null : onUseGps,
                        icon: busy
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, size: 18),
                        label: const Text('Use my GPS'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}