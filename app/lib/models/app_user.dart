class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String city;
  final String? bloodGroup;
  const AppUser({ required this.id, required this.name, required this.email, required this.role, required this.phone, required this.city, this.bloodGroup});
  bool get isDonor => role == 'donor';
  bool get isAdmin => role == 'admin';
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),  email: (j['email'] ?? '').toString(), role: (j['role'] ?? 'requester').toString(),
        phone: (j['phone'] ?? '').toString(), city: (j['city'] ?? '').toString(), bloodGroup: j['bloodGroup']?.toString(),
      );
}