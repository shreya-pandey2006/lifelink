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
  final DateTime? createdAt;
  const BloodRequest({
    required this.id, required this.bloodGroup, required this.units,
    required this.unitsAccepted, required this.hospitalName, required this.city,
    required this.urgency, required this.status, this.lat, this.lng, this.createdAt,
  });
  bool get isOpen => status == 'open';
  factory BloodRequest.fromJson(Map<String, dynamic> j) => BloodRequest(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        bloodGroup: (j['bloodGroup'] ?? '').toString(),
        units: _toInt(j['units'], 1),
        unitsAccepted: _toInt(j['unitsAccepted'], 0),
        hospitalName: (j['hospitalName'] ?? '').toString(),
        city: (j['city'] ?? '').toString(),
        urgency: _toInt(j['urgency'], 2),
        status: (j['status'] ?? 'open').toString(),
        lat: _toDouble(j['lat']),
        lng: _toDouble(j['lng']),
        createdAt:
            DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal(),
      );
}
int _toInt(dynamic v, int fallback) =>
    v is num ? v.toInt() : (int.tryParse('$v') ?? fallback);
double? _toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
