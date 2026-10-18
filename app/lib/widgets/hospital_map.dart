import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/theme.dart';
class HospitalMap extends StatelessWidget {
  final double? lat;
  final double? lng;
  final String title;
  final double height;
  const HospitalMap({ super.key, required this.lat, required this.lng, required this.title, this.height = 170 });
  @override
  Widget build(BuildContext context) {
    final la = lat;
    final ln = lng;
    if (la == null || ln == null) {
      return Container( height: 90, alignment: Alignment.center,
        decoration: BoxDecoration( color: const Color(0xFFF4F1F6), borderRadius: BorderRadius.circular(16)),
        child: const Padding( padding: EdgeInsets.all(12),
          child: Text('No map location was added for this hospital.', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13)),
        ),
      );
    }
    final point = LatLng(la, ln);
    return ClipRRect( borderRadius: BorderRadius.circular(16),
      child: SizedBox( height: height,
        child: IgnorePointer(
          child: GoogleMap( key: ValueKey('$la,$ln'), initialCameraPosition: CameraPosition(target: point, zoom: 15),
            markers: { Marker( markerId: const MarkerId('hospital'), position: point, infoWindow: InfoWindow(title: title) ) },
            liteModeEnabled: true, zoomControlsEnabled: false, myLocationButtonEnabled: false, mapToolbarEnabled: false,
          ),
        ),
      ),
    );
  }
}