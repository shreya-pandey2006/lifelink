class BloodRequest {
  final String id;
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

  factory BloodRequest.fromJson(Map<String, dynamic> j) => BloodRequest(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        bloodGroup: (j['bloodGroup'] ?? j['blood_group'] ?? '').toString(),
        units: _toInt(j['units'] ?? j['unitsRequired'], 1),
        unitsAccepted: _toInt(j['unitsAccepted'], 0),
        hospitalName: (j['hospitalName'] ?? j['hospital'] ?? '').toString(),
        city: (j['city'] ?? j['location'] ?? '').toString(),
        urgency: _urgency(j['urgency'] ?? j['urgencyLevel']),
        status: _status(j['status']),
        lat: _toDouble(j['lat'] ?? j['latitude']),
        lng: _toDouble(j['lng'] ?? j['longitude']),
        predictedUrgency: j['predictedUrgency']?.toString(),
        patient: j['patient'] is Map
            ? Map<String, dynamic>.from(j['patient'] as Map)
            : null,
        createdAt:
            DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal(),
      );
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

