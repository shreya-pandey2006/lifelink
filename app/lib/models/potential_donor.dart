import '../core/constants.dart';

class PotentialDonor {
  final String id;
  final String userId;
  final String name;
  final String bloodGroup;
  final String city;
  final bool available;
  final DateTime? lastDonationDate;
  final int? age;
  final double? weightKg;
  final double? hemoglobinGDl;
  final int totalDonations;
  final double? responseProbability;
  final double? lat;
  final double? lng;
  final double? distanceKm;
  final String? phone;

  const PotentialDonor({
    required this.id,
    required this.userId,
    this.name = 'Matching Donor',
    required this.bloodGroup,
    required this.city,
    required this.available,
    this.lastDonationDate,
    this.age,
    this.weightKg,
    this.hemoglobinGDl,
    this.totalDonations = 0,
    this.responseProbability,
    this.lat,
    this.lng,
    this.distanceKm,
    this.phone,
  });

  PotentialDonor copyWith({
    String? id,
    String? userId,
    String? name,
    String? bloodGroup,
    String? city,
    bool? available,
    DateTime? lastDonationDate,
    int? age,
    double? weightKg,
    double? hemoglobinGDl,
    int? totalDonations,
    double? responseProbability,
    double? lat,
    double? lng,
    double? distanceKm,
    String? phone,
  }) {
    return PotentialDonor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      city: city ?? this.city,
      available: available ?? this.available,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      hemoglobinGDl: hemoglobinGDl ?? this.hemoglobinGDl,
      totalDonations: totalDonations ?? this.totalDonations,
      responseProbability: responseProbability ?? this.responseProbability,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      distanceKm: distanceKm ?? this.distanceKm,
      phone: phone ?? this.phone,
    );
  }

  factory PotentialDonor.fromJson(Map<String, dynamic> j) {
    final u = j['user'];
    final userMap = u is Map ? Map<String, dynamic>.from(u) : null;
    final userName = userMap != null
        ? (userMap['name']?.toString() ?? 'Matching Donor')
        : (j['name']?.toString() ?? 'Matching Donor');
    final userId = userMap != null
        ? (userMap['_id'] ?? userMap['id'] ?? '').toString()
        : (u ?? '').toString();

    final cityVal = (j['city'] ?? userMap?['city'] ?? '').toString();

    double? parsedLat = _toDouble(j['lat'] ?? j['latitude'] ?? userMap?['lat']);
    double? parsedLng = _toDouble(j['lng'] ?? j['longitude'] ?? userMap?['lng']);

    if ((parsedLat == null || parsedLng == null) && cityVal.isNotEmpty) {
      final coords = getCoordinatesForCity(cityVal);
      if (coords != null) {
        parsedLat ??= coords.$1;
        parsedLng ??= coords.$2;
      }
    }

    final distVal = _toDouble(j['distanceKm'] ?? j['distance']);

    return PotentialDonor(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      userId: userId,
      name: userName,
      bloodGroup: (j['bloodGroup'] ?? '').toString(),
      city: cityVal,
      available: j['available'] != false,
      lastDonationDate:
          DateTime.tryParse((j['lastDonationDate'] ?? '').toString())?.toLocal(),
      age: j['age'] is num
          ? (j['age'] as num).toInt()
          : int.tryParse('${j['age']}'),
      weightKg: j['weightKg'] is num
          ? (j['weightKg'] as num).toDouble()
          : double.tryParse('${j['weightKg']}'),
      hemoglobinGDl: j['hemoglobinGDl'] is num
          ? (j['hemoglobinGDl'] as num).toDouble()
          : double.tryParse('${j['hemoglobinGDl']}'),
      totalDonations: j['totalDonations'] is num
          ? (j['totalDonations'] as num).toInt()
          : (int.tryParse('${j['totalDonations']}') ?? 0),
      responseProbability: j['responseProbability'] is num
          ? (j['responseProbability'] as num).toDouble()
          : double.tryParse('${j['responseProbability']}'),
      lat: parsedLat,
      lng: parsedLng,
      distanceKm: distVal,
      // Privacy rule: Available donors' phone numbers are never stored or exposed
      phone: null,
    );
  }
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
