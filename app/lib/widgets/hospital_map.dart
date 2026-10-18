import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import 'lifelink_map_view.dart';

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

    final isCityFallback = (lat == null || lng == null);

    return LifeLinkMapView(
      key: ValueKey('hosp_$la,$ln'),
      latitude: la,
      longitude: ln,
      zoom: isCityFallback ? 13 : 14.5,
      height: height,
      showRadarRings: false,
      badgeText: isCityFallback && city != null && city!.isNotEmpty
          ? '$city Hospital Area'
          : 'Destination Hospital',
      badgeIcon: Icons.local_hospital,
      badgeColor: kPrimaryDark,
      markerTitle: title.isNotEmpty ? title : 'Hospital Location',
      markerSubtitle: isCityFallback && city != null && city!.isNotEmpty
          ? '$city hospital area'
          : 'Destination hospital',
    );
  }
}