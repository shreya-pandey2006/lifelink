import '../core/format.dart';

class Donation {
  final String requestId;
  final String hospitalName;
  final String bloodGroup;
  final String city;
  final int units;
  final String status;
  final String? message;
  final DateTime? date;

  const Donation({
    required this.requestId,
    required this.hospitalName,
    required this.bloodGroup,
    required this.city,
    required this.units,
    required this.status,
    this.message,
    this.date,
  });

  factory Donation.fromJson(Map<String, dynamic> j) {
    final req = j['bloodRequest'] is Map
        ? Map<String, dynamic>.from(j['bloodRequest'] as Map)
        : <String, dynamic>{};
    final bloodGroup = (req['bloodGroup'] ?? j['bloodGroup'] ?? '').toString();
    final city = (req['city'] ?? j['city'] ?? '').toString();
    final hospital = (req['hospitalName'] ??
            req['hospital'] ??
            j['hospitalName'] ??
            (city.isNotEmpty ? '$city Hospital' : 'Blood Request'))
        .toString();
    return Donation(
      requestId: (req['_id'] ?? req['id'] ?? j['requestId'] ?? j['id'] ?? '')
          .toString(),
      hospitalName: hospital,
      bloodGroup: bloodGroup,
      city: city,
      units: asInt(req['units'] ?? j['units'], 1),
      status: (j['status'] ?? req['status'] ?? 'accepted').toString(),
      message: j['message']?.toString(),
      date: DateTime.tryParse(
              (j['createdAt'] ?? j['date'] ?? req['createdAt'] ?? '')
                  .toString())
          ?.toLocal(),
    );
  }
}