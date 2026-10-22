class Responder {
  final String name;
  final String status;
  final String? phone;
  final String? bloodGroup;
  final String? city;
  final DateTime? respondedAt;

  const Responder({
    required this.name,
    required this.status,
    this.phone,
    this.bloodGroup,
    this.city,
    this.respondedAt,
  });

  bool get accepted => status == 'accepted';

  factory Responder.fromJson(Map<String, dynamic> j) {
    final user = j['user'] is Map
        ? Map<String, dynamic>.from(j['user'] as Map)
        : const <String, dynamic>{};
    final donor = j['donor'] is Map
        ? Map<String, dynamic>.from(j['donor'] as Map)
        : const <String, dynamic>{};

    String? pick(List<dynamic> values) {
      for (final v in values) {
        if (v != null && v.toString().isNotEmpty) return v.toString();
      }
      return null;
    }

    return Responder(
      name: pick([j['donorName'], j['name'], user['name'], donor['name']]) ??
          'Donor',
      status: (j['status'] ?? 'potential').toString().toLowerCase(),
      phone: pick([j['phone'], user['phone'], donor['phone']]),
      bloodGroup: pick([j['bloodGroup'], donor['bloodGroup'], user['bloodGroup']]),
      city: pick([j['city'], donor['city'], user['city']]),
      respondedAt: DateTime.tryParse(
              (j['respondedAt'] ?? j['createdAt'] ?? '').toString())
          ?.toLocal(),
    );
  }
}