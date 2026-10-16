class PotentialDonor {
  final String id;
  final String userId;
  final String bloodGroup;
  final String city;
  final bool available;
  final DateTime? lastDonationDate;
  final int? age;
  final double? weightKg;
  final double? hemoglobinGDl;
  final int totalDonations;

  const PotentialDonor({
    required this.id,
    required this.userId,
    required this.bloodGroup,
    required this.city,
    required this.available,
    this.lastDonationDate,
    this.age,
    this.weightKg,
    this.hemoglobinGDl,
    this.totalDonations = 0,
  });

  factory PotentialDonor.fromJson(Map<String, dynamic> j) => PotentialDonor(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        userId: (j['user'] ?? '').toString(),
        bloodGroup: (j['bloodGroup'] ?? '').toString(),
        city: (j['city'] ?? '').toString(),
        available: j['available'] != false,
        lastDonationDate: DateTime.tryParse((j['lastDonationDate'] ?? '').toString())?.toLocal(),
        age: j['age'] is num ? (j['age'] as num).toInt() : int.tryParse('${j['age']}'),
        weightKg: j['weightKg'] is num ? (j['weightKg'] as num).toDouble() : double.tryParse('${j['weightKg']}'),
        hemoglobinGDl: j['hemoglobinGDl'] is num
            ? (j['hemoglobinGDl'] as num).toDouble()
            : double.tryParse('${j['hemoglobinGDl']}'),
        totalDonations: j['totalDonations'] is num
            ? (j['totalDonations'] as num).toInt()
            : (int.tryParse('${j['totalDonations']}') ?? 0),
      );
}
