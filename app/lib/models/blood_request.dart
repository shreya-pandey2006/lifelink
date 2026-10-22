import '../core/constants.dart';

class BloodRequest {
  final String id;
  final String? requesterId;
  final String? requesterName;
  final String? requesterPhone;
  final String bloodGroup;
  final int units;
  final int unitsAccepted;
  final String hospitalName;
  final String city;
  final int urgency;
  final String status;
  final double? lat;
  final double? lng;
  final String? predictedUrgency;
  final Map<String, dynamic>? patient;
  final DateTime? createdAt;

  const BloodRequest({
    required this.id,
    this.requesterId,
    this.requesterName,
    this.requesterPhone,
    required this.bloodGroup,
    required this.units,
    required this.unitsAccepted,
    required this.hospitalName,
    required this.city,
    required this.urgency,
    required this.status,
    this.lat,
    this.lng,
    this.predictedUrgency,
    this.patient,
    this.createdAt,
  });

  bool get isOpen => status == 'open';

  BloodRequest copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? requesterPhone,
    String? bloodGroup,
    int? units,
    int? unitsAccepted,
    String? hospitalName,
    String? city,
    int? urgency,
    String? status,
    double? lat,
    double? lng,
    String? predictedUrgency,
    Map<String, dynamic>? patient,
    DateTime? createdAt,
  }) {
    return BloodRequest(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterPhone: requesterPhone ?? this.requesterPhone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      units: units ?? this.units,
      unitsAccepted: unitsAccepted ?? this.unitsAccepted,
      hospitalName: hospitalName ?? this.hospitalName,
      city: city ?? this.city,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      predictedUrgency: predictedUrgency ?? this.predictedUrgency,
      patient: patient ?? this.patient,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory BloodRequest.fromJson(Map<String, dynamic> raw) {
    final j = (raw['bloodRequest'] is Map)
        ? Map<String, dynamic>.from(raw['bloodRequest'] as Map)
        : (raw['request'] is Map)
            ? Map<String, dynamic>.from(raw['request'] as Map)
            : raw;

    String? reqId;
    String? reqName;
    String? reqPhone;
    final r = j['requester'] ?? j['requesterId'];
    if (r is Map) {
      reqId = (r['_id'] ?? r['id'])?.toString();
      reqName = (r['name'] ?? j['requesterName'])?.toString();
      reqPhone = (r['phone'] ?? j['requesterPhone'])?.toString();
    } else if (r != null) {
      reqId = r.toString();
      reqName = j['requesterName']?.toString();
      reqPhone = j['requesterPhone']?.toString();
    }

    final cityVal = (j['city'] ?? j['location'] ?? '').toString().trim();
    final patientMap = j['patient'] is Map
        ? Map<String, dynamic>.from(j['patient'] as Map)
        : null;

    reqPhone ??= (patientMap?['phone'] ??
            patientMap?['contact'] ??
            patientMap?['contactNumber'] ??
            j['contactPhone'] ??
            j['phone'])
        ?.toString();
    reqName ??= (patientMap?['contactName'] ??
            patientMap?['requesterName'] ??
            patientMap?['attendantName'] ??
            j['requesterName'])
        ?.toString();

    final rawHospital = (j['hospitalName'] ??
            j['hospital'] ??
            j['facility'] ??
            patientMap?['hospital'] ??
            patientMap?['hospitalName'] ??
            patientMap?['facility'] ??
            '')
        .toString()
        .trim();
    final hospitalVal = rawHospital.isNotEmpty
        ? rawHospital
        : (cityVal.isNotEmpty ? 'Hospital in $cityVal' : 'Medical Center');

    double? parsedLat = _toDouble(
      j['lat'] ??
          j['latitude'] ??
          j['hospitalLatitude'] ??
          patientMap?['lat'] ??
          patientMap?['latitude'] ??
          patientMap?['hospitalLatitude'],
    );
    double? parsedLng = _toDouble(
      j['lng'] ??
          j['longitude'] ??
          j['hospitalLongitude'] ??
          patientMap?['lng'] ??
          patientMap?['longitude'] ??
          patientMap?['hospitalLongitude'],
    );

    if ((parsedLat == null || parsedLng == null) && cityVal.isNotEmpty) {
      final cityCoords = getCoordinatesForCity(cityVal);
      if (cityCoords != null) {
        parsedLat ??= cityCoords.$1;
        parsedLng ??= cityCoords.$2;
      }
    }

    return BloodRequest(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      requesterId: reqId,
      requesterName: reqName,
      requesterPhone: reqPhone,
      bloodGroup: (j['bloodGroup'] ?? j['blood_group'] ?? '').toString().trim(),
      units: _toInt(j['units'] ?? j['unitsRequired'], 1),
      unitsAccepted: _toInt(j['unitsAccepted'], 0),
      hospitalName: hospitalVal,
      city: cityVal,
      urgency: _urgency(j['urgency'] ?? j['urgencyLevel']),
      status: _status(j['status']),
      lat: parsedLat,
      lng: parsedLng,
      predictedUrgency: j['predictedUrgency']?.toString(),
      patient: patientMap,
      createdAt:
          DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal(),
    );
  }
}

int _urgency(dynamic v) {
  if (v is num) return v.toInt().clamp(1, 3);
  switch ('$v'.toLowerCase()) {
    case 'low':
    case 'normal':
      return 1;
    case 'high':
    case 'urgent':
      return 2;
    case 'critical':
    case 'emergency':
      return 3;
    case 'medium':
      return 2;
  }
  return 2;
}

String _status(dynamic v) {
  final s = '${v ?? 'open'}'.toLowerCase();
  return (s == 'pending' || s == 'active') ? 'open' : s;
}

int _toInt(dynamic v, int fallback) =>
    v is num ? v.toInt() : (int.tryParse('$v') ?? fallback);
double? _toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

