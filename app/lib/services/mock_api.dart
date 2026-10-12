import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class MockApi {
  MockApi._();
  static final MockApi instance = MockApi._();
  static const _usersKey = 'mock_users';
  static const _requestsKey = 'mock_requests';
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
      case 'POST /requests':
        return _createRequest(body ?? {}, token);
      case 'GET /requests':
        return _listRequests(token);
    }
    throw ApiException('Mock API: $route is not implemented yet', 404);
  }
  String _userId(String? token) {
    const prefix = 'mock-token-';
    if (token == null || !token.startsWith(prefix)) {
      throw ApiException('Not authenticated', 401);
    }
    return token.substring(prefix.length);
  }
  Future<Map<String, dynamic>> _register(Map<String, dynamic> b) async {
    final users = await _loadUsers();
    final email = (b['email'] ?? '').toString().toLowerCase();
    if (users.any((u) => u['email'].toString().toLowerCase() == email)) {
      throw ApiException('This email is already registered.', 409);
    }
    final user = <String, dynamic>{ 'id': '${DateTime.now().millisecondsSinceEpoch}', 'name': b['name'], 'email': email, 'password': b['password'], 'phone': b['phone'], 'city': b['city'], 'role': b['role'], 'bloodGroup': b['bloodGroup']};
    users.add(user);
    await _saveUsers(users);
    return {'token': 'mock-token-${user['id']}', 'user': _public(user)};
  }
  Future<Map<String, dynamic>> _login(Map<String, dynamic> b) async {
    final users = await _loadUsers();
    final email = (b['email'] ?? '').toString().toLowerCase();
    final matches = users.where((u) => u['email'].toString().toLowerCase() == email && u['password'] == b['password']);

    if (matches.isEmpty) {
      throw ApiException('Invalid email or password.', 401);
    }
    final user = matches.first;
    return {'token': 'mock-token-${user['id']}', 'user': _public(user)};
  }

  Future<Map<String, dynamic>> _me(String? token) async {
    final id = _userId(token);
    final users = await _loadUsers();
    final matches = users.where((u) => u['id'].toString() == id);
    if (matches.isEmpty) throw ApiException('Not authenticated', 401);
    return {'user': _public(matches.first)};
  }
  Future<Map<String, dynamic>> _createRequest(
      Map<String, dynamic> b, String? token) async {
    final userId = _userId(token);
    final group = (b['bloodGroup'] ?? '').toString();
    final units = b['units'];
    if (group.isEmpty) throw ApiException('Blood group is required.', 400);
    if (units is! int || units < 1 || units > 10) {
      throw ApiException('Units must be between 1 and 10.', 400);
    }
    if ((b['hospitalName'] ?? '').toString().trim().isEmpty) {
      throw ApiException('Hospital name is required.', 400);
    }
    final all = await _loadRequests();
    final request = <String, dynamic>{
      'id': 'REQ-${DateTime.now().millisecondsSinceEpoch}', 'requesterId': userId, 'bloodGroup': group, 'units': units,
      'unitsAccepted': 0, 'hospitalName': b['hospitalName'], 'city': b['city'], 'urgency': b['urgency'] ?? 2, 'status': 'open',
      'lat': ?b['lat'], 'lng': ?b['lng'], 'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    all.insert(0, request);
    await _saveRequests(all);
    return {'request': request};
  }
  Future<Map<String, dynamic>> _listRequests(String? token) async {
    final userId = _userId(token);
    final all = await _loadRequests();
    final mine = all.where((r) => r['requesterId'] == userId).toList();
    return {'requests': mine};
  }
  Map<String, dynamic> _public(Map<String, dynamic> user) =>
      Map<String, dynamic>.from(user)..remove('password');
  List<Map<String, dynamic>> _seedUsers() => [
        { 'id': '1', 'name': 'Demo Donor', 'email': 'donor@lifelink.test','password': '123456', 'phone': '9876543210', 'city': 'Ghaziabad', 'role': 'donor', 'bloodGroup': 'O-' },
        { 'id': '2', 'name': 'Demo Requester', 'email': 'requester@lifelink.test', 'password': '123456', 'phone': '9876500000', 'city': 'Ghaziabad', 'role': 'requester' },
      ];

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) {
      final seed = _seedUsers();
      await _saveUsers(seed);
      return seed;
    }
    return _decodeList(raw);
  }
  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }
  Future<List<Map<String, dynamic>>> _loadRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_requestsKey);
    return raw == null ? [] : _decodeList(raw);
  }
  Future<void> _saveRequests(List<Map<String, dynamic>> requests) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_requestsKey, jsonEncode(requests));
  }
  List<Map<String, dynamic>> _decodeList(String raw) =>
      (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
}
