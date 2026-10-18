import '../core/constants.dart';
import '../core/format.dart';

class AlertItem {
  final String requestId;
  final String bloodGroup;
  final int units;
  final String hospitalName;
  final String city;
  final int urgency;
  final String status;
  final double? lat;
  final double? lng;
  final DateTime? createdAt;

  const AlertItem({
    required this.requestId,
    required this.bloodGroup,
    required this.units,
    required this.hospitalName,
    required this.city,
    required this.urgency,
    required this.status,
    this.lat,
    this.lng,
    this.createdAt,
  });

  bool get isCritical => urgency == 3;

  factory AlertItem.fromJson(Map<String, dynamic> j) {
    final cityVal = (j['city'] ?? '').toString().trim();
    final patientMap = j['patient'] is Map
        ? Map<String, dynamic>.from(j['patient'] as Map)
        : null;

    final rawHospital = (j['hospitalName'] ??
            j['hospital'] ??
            patientMap?['hospital'] ??
            patientMap?['hospitalName'] ??
            '')
        .toString()
        .trim();
    final hospitalVal = rawHospital.isNotEmpty
        ? rawHospital
        : (cityVal.isNotEmpty ? 'Hospital in $cityVal' : 'Medical Center');

    double? parsedLat = asDouble(j['lat'] ??
        j['latitude'] ??
        j['hospitalLatitude'] ??
        patientMap?['lat'] ??
        patientMap?['latitude']);
    double? parsedLng = asDouble(j['lng'] ??
        j['longitude'] ??
        j['hospitalLongitude'] ??
        patientMap?['lng'] ??
        patientMap?['longitude']);

    if ((parsedLat == null || parsedLng == null) && cityVal.isNotEmpty) {
      final cityCoords = getCoordinatesForCity(cityVal);
      if (cityCoords != null) {
        parsedLat ??= cityCoords.$1;
        parsedLng ??= cityCoords.$2;
      }
    }

    return AlertItem(
      requestId: (j['requestId'] ?? j['id'] ?? j['_id'] ?? '').toString(),
      bloodGroup: (j['bloodGroup'] ?? '').toString(),
      units: asInt(j['units'], 1),
      hospitalName: hospitalVal,
      city: cityVal,
      urgency: asInt(j['urgency'], 2),
      status: (j['status'] ?? 'open').toString(),
      lat: parsedLat,
      lng: parsedLng,
      createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal(),
    );
  }
}