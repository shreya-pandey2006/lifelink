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
    required this.requestId, required this.bloodGroup, required this.units, required this.hospitalName, required this.city,
    required this.urgency, required this.status, this.lat, this.lng, this.createdAt,
  });
  bool get isCritical => urgency == 3;
  factory AlertItem.fromJson(Map<String, dynamic> j) => AlertItem(
        requestId: (j['requestId'] ?? j['id'] ?? j['_id'] ?? '').toString(), bloodGroup: (j['bloodGroup'] ?? '').toString(),
        units: asInt(j['units'], 1), hospitalName: (j['hospitalName'] ?? '').toString(), city: (j['city'] ?? '').toString(), urgency: asInt(j['urgency'], 2),
        status: (j['status'] ?? 'open').toString(), lat: asDouble(j['lat']), lng: asDouble(j['lng']),
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal(),
      );
}