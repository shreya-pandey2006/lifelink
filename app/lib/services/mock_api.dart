import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
class MockApi {
  MockApi._();
  static final MockApi instance = MockApi._();
  static const _usersKey = 'mock_users';

  Future<dynamic> handle(
    String method,
    String path,
    Map<String, dynamic>? body,
    String? token,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final route = '$method $path';
    switch (route) {
      case 'POST /auth/register':
        return _register(body ?? {});
      case 'POST /auth/login':
        return _login(body ?? {});
      case 'GET /auth/me':
        return _me(token);
    }
    throw ApiException('Mock API: $route is not implemented yet', 404);
  }
  Future<Map<String, dynamic>> _register(Map<String, dynamic> b) async {
    final users = await _loadUsers();
    final email = (b['email'] ?? '').toString().toLowerCase();

    if (users.any((u) => u['email'].toString().toLowerCase() == email)) {
      throw ApiException('This email is already registered.', 409);
    }

    final user = <String, dynamic>{
      'id': '${DateTime.now().millisecondsSinceEpoch}','name': b['name'],
      'email': email,'password': b['password'],'phone': b['phone'], 'city': b['city'], 'role': b['role'],
      if (b['bloodGroup'] != null) 'bloodGroup': b['bloodGroup'],
    };
    users.add(user);
    await _saveUsers(users);

    return {'token': 'mock-token-${user['id']}', 'user': _public(user)};
  }
  Future<Map<String, dynamic>> _login(Map<String, dynamic> b) async {
    final users = await _loadUsers();
    final email = (b['email'] ?? '').toString().toLowerCase();
    final matches = users.where((u) =>
        u['email'].toString().toLowerCase() == email &&
        u['password'] == b['password']);
    if (matches.isEmpty) {
      throw ApiException('Invalid email or password.', 401);
    }
    final user = matches.first;
    return {'token': 'mock-token-${user['id']}', 'user': _public(user)};
  }

  Future<Map<String, dynamic>> _me(String? token) async {
    const prefix = 'mock-token-';
    if (token == null || !token.startsWith(prefix)) {
      throw ApiException('Not authenticated', 401);
    }
    final id = token.substring(prefix.length);
    final users = await _loadUsers();
    final matches = users.where((u) => u['id'].toString() == id);
    if (matches.isEmpty) throw ApiException('Not authenticated', 401);
    return {'user': _public(matches.first)};
  }
  Map<String, dynamic> _public(Map<String, dynamic> user) =>
      Map<String, dynamic>.from(user)..remove('password');

  List<Map<String, dynamic>> _seedUsers() => [
        {
          'id': '1','name': 'Demo Donor','email': 'donor@lifelink.test','password': '123456','phone': '9876543210','city': 'Ghaziabad', 'role': 'donor', 'bloodGroup': 'O-',
        },
        {
          'id': '2','name': 'Demo Requester','email': 'requester@lifelink.test','password': '123456','phone': '9876500000','city': 'Ghaziabad','role': 'requester',
        },
      ];

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) {
      final seed = _seedUsers();
      await _saveUsers(seed);
      return seed;
    }
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }
}