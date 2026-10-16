import '../core/format.dart';
class Donation {
  final String requestId;
  final String hospitalName;
  final String bloodGroup;
  final String city;
  final int units;
  final String status;
  final DateTime? date;
  const Donation({ required this.requestId, required this.hospitalName, required this.bloodGroup, required this.city, required this.units, required this.status, this.date});
  factory Donation.fromJson(Map<String, dynamic> j) => Donation(
        requestId: (j['requestId'] ?? '').toString(), hospitalName: (j['hospitalName'] ?? '').toString(), bloodGroup: (j['bloodGroup'] ?? '').toString(),
        city: (j['city'] ?? '').toString(), units: asInt(j['units'], 1), status: (j['status'] ?? 'matched').toString(), date: DateTime.tryParse((j['date'] ?? '').toString())?.toLocal(),
      );
}