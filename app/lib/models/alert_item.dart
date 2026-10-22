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
  final String department;
  final int donorsPinged;
  final String routeSnippet;
  final String? requesterName;
  final String? requesterPhone;

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
    this.department = '',
    this.donorsPinged = 0,
    this.routeSnippet = '',
    this.requesterName,
    this.requesterPhone,
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
        : (cityVal.isNotEmpty ? 'Hospital in $cityVal' : 'Hospital');

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

    final rawUrgency = asInt(j['urgency'], 2);
    final rawHealth = (patientMap?['healthIssue'] ??
            j['healthIssue'] ??
            j['department'] ??
            '')
        .toString()
        .trim();

    final dept = rawHealth.isNotEmpty
        ? rawHealth
        : (rawUrgency == 3
            ? 'Emergency Blood Request'
            : 'Blood Request');

    final req = j['requester'];
    final reqName = (req is Map ? req['name'] : null)?.toString() ??
        (j['requesterName'] ?? patientMap?['contactName'] ?? patientMap?['requesterName'])?.toString();
    final reqPhone = (req is Map ? req['phone'] : null)?.toString() ??
        (j['requesterPhone'] ?? patientMap?['phone'] ?? patientMap?['contact'] ?? patientMap?['contactNumber'])?.toString();

    return AlertItem(
      requestId: (j['requestId'] ?? j['id'] ?? j['_id'] ?? '').toString(),
      bloodGroup: (j['bloodGroup'] ?? 'O-').toString(),
      units: asInt(j['units'], 1),
      hospitalName: hospitalVal,
      city: cityVal,
      urgency: rawUrgency,
      status: (j['status'] ?? 'open').toString(),
      lat: parsedLat,
      lng: parsedLng,
      createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal(),
      department: dept,
      donorsPinged: asInt(j['donorsPinged'] ?? j['matchingDonorsCount'], 0),
      routeSnippet: (j['routeSnippet'] ?? '').toString(),
      requesterName: reqName,
      requesterPhone: reqPhone,
    );
  }
}