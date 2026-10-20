import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class HospitalMap extends StatelessWidget {
  final double? lat;
  final double? lng;
  final String title;
  final String? city;
  final double height;

  const HospitalMap({
    super.key,
    required this.lat,
    required this.lng,
    required this.title,
    this.city,
    this.height = 170,
  });

  @override
  Widget build(BuildContext context) {
    double? la = lat;
    double? ln = lng;

    if ((la == null || ln == null) && city != null && city!.trim().isNotEmpty) {
      final cityCoords = getCoordinatesForCity(city!.trim());
      if (cityCoords != null) {
        la = cityCoords.$1;
        ln = cityCoords.$2;
      }
    }

    if ((la == null || ln == null) && title.toLowerCase().contains('in ')) {
      final parts = title.split(RegExp(r'\bin\b', caseSensitive: false));
      if (parts.length > 1) {
        final guessedCity = parts.last.trim();
        final cityCoords = getCoordinatesForCity(guessedCity);
        if (cityCoords != null) {
          la = cityCoords.$1;
          ln = cityCoords.$2;
        }
      }
    }

    if (la == null || ln == null) {
      return Container(
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'No map location was added for this hospital.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 13),
          ),
        ),
      );
    }

    final point = LatLng(la, ln);
    final isCityFallback = (lat == null || lng == null);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            GoogleMap(
              key: ValueKey('$la,$ln'),
              initialCameraPosition: CameraPosition(
                target: point,
                zoom: isCityFallback ? 14 : 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('hospital'),
                  position: point,
                  infoWindow: InfoWindow(
                    title: title.isNotEmpty ? title : 'Hospital Location',
                    snippet: isCityFallback && city != null && city!.isNotEmpty
                        ? '$city hospital area'
                        : 'Destination hospital',
                  ),
                ),
              },
              liteModeEnabled: true,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    const Icon(Icons.location_on, color: kPrimaryDark, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      title.isNotEmpty ? title : (city ?? 'Hospital Location'),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: kInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}