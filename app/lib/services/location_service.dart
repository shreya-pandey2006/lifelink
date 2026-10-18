import 'package:geolocator/geolocator.dart';
class LocationException implements Exception {
  final String message;
  LocationException(this.message);
  @override
  String toString() => message;
}
class LocationService {
  static Future<Position> currentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw LocationException('Turn on location (GPS) on your phone and try again.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationException('Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException( 'Location permission is blocked. Allow it for LifeLink in the phone settings.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings( accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
    );
  }
  static double distanceKm( double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }
}