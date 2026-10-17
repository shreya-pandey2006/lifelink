import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import 'api_client.dart';

/// A fake backend that lives inside the app, so you can build and test every
/// screen before the real API is ready. It returns the JSON shapes that the
/// API contract describes.
///
/// Demo accounts (password 123456):
///   donor@lifelink.test       (donor, O-, Ghaziabad)
///   requester@lifelink.test   (requester, Ghaziabad)
class MockApi {
  MockApi._();
  static final MockApi instance = MockApi._();

  static const _usersKey = 'mock_users';
  // New keys, so the sample data below appears even after earlier tests.
  static const _requestsKey = 'mock_requests_v3';
  static const _responsesKey = 'mock_responses_v1';
  static const _notificationsKey = 'mock_notifications_v1';

  Future<dynamic> handle(
    String method,
    String path,
    Map<String, dynamic>? body,
    String? token,
  ) async {
    // A short delay so loading spinners are visible, like a real network.
    await Future.delayed(const Duration(milliseconds: 500));
    final b = body ?? <String, dynamic>{};
    final route = '$method $path';

    switch (route) {
      case 'POST /auth/register':
        return _register(b);
      case 'POST /auth/login':
        return _login(b);
      case 'GET /auth/me':
        return {'user': _public(await _currentUser(token))};
      case 'POST /requests':
        return _createRequest(b, token);
      case 'GET /requests':
        return _listRequests(token);
      case 'GET /alerts':
        return _alerts(token);
      case 'GET /donors/me':
        return _donorMe(token);
      case 'PUT /donors/me':
        return _updateLocation(b, token);
      case 'PATCH /donors/me/availability':
        return _setAvailability(b, token);
      case 'PATCH /donors/ml-details':
        return _saveHealth(b, token);
      case 'GET /donations/me':
        return _donations(token);
      case 'GET /notifications':
        return _notifications(token);
      case 'PATCH /notifications/read-all':
        return _readAll(token);
    }

    final detail = RegExp(r'^/requests/([^/]+)$').firstMatch(path);
    if (method == 'GET' && detail != null) {
      return _requestDetail(detail.group(1)!, token);
    }
    final status = RegExp(r'^/requests/([^/]+)/status$').firstMatch(path);
    if (method == 'PATCH' && status != null) {
      return _setRequestStatus(status.group(1)!, b, token);
    }
    final respond = RegExp(r'^/responses/([^/]+)/(accept|decline)$').firstMatch(path);
    if (method == 'POST' && respond != null) {
      return _respond(respond.group(1)!, respond.group(2) == 'accept', token);
    }

    throw ApiException('Mock API: $route is not implemented yet', 404);
  }

  // ---------- helpers ----------

  String _userId(String? token) {
    const prefix = 'mock-token-';
    if (token == null || !token.startsWith(prefix)) {
      throw ApiException('Not authenticated', 401);
    }
    return token.substring(prefix.length);
  }

  Future<Map<String, dynamic>> _currentUser(String? token) async {
    final id = _userId(token);
    final users = await _loadUsers();
    final matches = users.where((u) => u['id'].toString() == id);
    if (matches.isEmpty) throw ApiException('Not authenticated', 401);
    return matches.first;
  }

  Future<Map<String, dynamic>> _donorUser(String? token) async {
    final me = await _currentUser(token);
    if (me['role'] != 'donor') {
      throw ApiException('Only donors can do this.', 403);
    }
    return me;
  }

  Map<String, dynamic> _public(Map<String, dynamic> user) =>
      Map<String, dynamic>.from(user)..remove('password');

  // Same city, a blood group this donor can give, and available.
  bool _donorMatches(Map<String, dynamic> donor, Map<String, dynamic> request) {
    if (donor['role'] != 'donor') return false;
    if (donor['available'] == false) return false;
    if (donor['city'] != request['city']) return false;
    final canGiveTo = kDonatesTo[donor['bloodGroup']] ?? const <String>[];
    return canGiveTo.contains(request['bloodGroup']);
  }

  Future<void> _notify(
    String userId, {
    required String type,
    required String title,
    required String message,
    String? requestId,
  }) async {
    final all = await _loadNotifications();
    all.insert(0, {
      'id': 'N-${DateTime.now().microsecondsSinceEpoch}',
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'requestId': requestId,
      'read': false,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    await _saveNotifications(all);
  }

  // ---------- auth ----------

  Future<Map<String, dynamic>> _register(Map<String, dynamic> b) async {
    final users = await _loadUsers();
    final email = (b['email'] ?? '').toString().toLowerCase();

    if (users.any((u) => u['email'].toString().toLowerCase() == email)) {
      throw ApiException('This email is already registered.', 409);
    }

    final user = <String, dynamic>{
      'id': '${DateTime.now().millisecondsSinceEpoch}',
      'name': b['name'],
      'email': email,
      'password': b['password'],
      'phone': b['phone'],
      'city': b['city'],
      'role': b['role'],
      'bloodGroup': ?b['bloodGroup'],
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

  // ---------- requests (requester side) ----------

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
      'id': 'REQ-${DateTime.now().millisecondsSinceEpoch}',
      'requesterId': userId,
      'bloodGroup': group,
      'units': units,
      'unitsAccepted': 0,
      'hospitalName': b['hospitalName'],
      'city': b['city'],
      'urgency': b['urgency'] ?? 2,
      'status': 'open',
      'lat': ?b['lat'],
      'lng': ?b['lng'],
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    all.insert(0, request);
    await _saveRequests(all);

    // Tell every matching donor.
    final critical = request['urgency'] == 3;
    final users = await _loadUsers();
    for (final u in users) {
      if (u['id'].toString() == userId || !_donorMatches(u, request)) continue;
      await _notify(
        u['id'].toString(),
        type: 'alert',
        title: critical
            ? 'Critical $group Blood Alert Near You'
            : 'New $group Request Nearby',
        message:
            '${request['hospitalName']} posted an emergency request for $units ${units == 1 ? 'unit' : 'units'}.',
        requestId: request['id'] as String,
      );
    }
    return {'request': request};
  }

  // A requester sees only their own requests, newest first.
  Future<Map<String, dynamic>> _listRequests(String? token) async {
    final userId = _userId(token);
    final all = await _loadRequests();
    return {'requests': all.where((r) => r['requesterId'] == userId).toList()};
  }

  Future<Map<String, dynamic>> _requestDetail(String id, String? token) async {
    final userId = _userId(token);
    final all = await _loadRequests();
    final matches = all.where((r) => r['id'] == id);
    if (matches.isEmpty) throw ApiException('Request not found.', 404);
    final request = matches.first;
    if (request['requesterId'] != userId) {
      throw ApiException('You can only view your own requests.', 403);
    }

    final responses = (await _loadResponses())
        .where((r) => r['requestId'] == id)
        .map((r) => {
              'donorName': r['donorName'],
              'status': r['status'],
              // The phone number is shared only after a donor accepts.
              'phone': r['status'] == 'accepted' ? r['phone'] : null,
              'respondedAt': r['respondedAt'],
            })
        .toList();
    return {'request': request, 'responses': responses};
  }

  Future<Map<String, dynamic>> _setRequestStatus(
      String id, Map<String, dynamic> b, String? token) async {
    final userId = _userId(token);
    final newStatus = (b['status'] ?? '').toString();
    if (newStatus != 'cancelled' && newStatus != 'fulfilled') {
      throw ApiException('Status must be "cancelled" or "fulfilled".', 400);
    }

    final all = await _loadRequests();
    final index = all.indexWhere((r) => r['id'] == id);
    if (index < 0) throw ApiException('Request not found.', 404);
    if (all[index]['requesterId'] != userId) {
      throw ApiException('You can only change your own requests.', 403);
    }

    final current = all[index]['status'];
    if (current == 'fulfilled' || current == 'cancelled') {
      throw ApiException('This request is already closed.', 409);
    }
    if (newStatus == 'fulfilled' && current != 'matched') {
      throw ApiException('Only a matched request can be marked as fulfilled.', 409);
    }

    all[index]['status'] = newStatus;
    await _saveRequests(all);

    // Tell the donors who accepted.
    final accepted = (await _loadResponses())
        .where((r) => r['requestId'] == id && r['status'] == 'accepted');
    for (final r in accepted) {
      await _notify(
        r['donorId'].toString(),
        type: newStatus,
        title: newStatus == 'fulfilled' ? 'Request Fulfilled' : 'Request Cancelled',
        message: newStatus == 'fulfilled'
            ? 'The request at ${all[index]['hospitalName']} was fulfilled. Thank you for helping!'
            : 'The request at ${all[index]['hospitalName']} was cancelled. You no longer need to travel.',
        requestId: id,
      );
    }
    return {'request': all[index]};
  }

  // ---------- donor side ----------

  // Open requests that match this donor and that they have not answered yet.
  Future<Map<String, dynamic>> _alerts(String? token) async {
    final me = await _donorUser(token);
    final myId = me['id'].toString();

    final answered = (await _loadResponses())
        .where((r) => r['donorId'] == myId)
        .map((r) => r['requestId'])
        .toSet();

    final matching = (await _loadRequests())
        .where((r) =>
            r['status'] == 'open' &&
            r['requesterId'] != myId &&
            !answered.contains(r['id']) &&
            _donorMatches(me, r) &&
            (r['unitsAccepted'] as int) < (r['units'] as int))
        .toList();

    // Most urgent first, then newest first.
    matching.sort((a, b) {
      final byUrgency = (b['urgency'] as int).compareTo(a['urgency'] as int);
      if (byUrgency != 0) return byUrgency;
      return (b['createdAt'] as String).compareTo(a['createdAt'] as String);
    });

    return {
      'alerts': matching
          .map((r) => {
                'requestId': r['id'],
                'bloodGroup': r['bloodGroup'],
                'units': r['units'],
                'hospitalName': r['hospitalName'],
                'city': r['city'],
                'lat': r['lat'],
                'lng': r['lng'],
                'urgency': r['urgency'],
                'status': r['status'],
                'createdAt': r['createdAt'],
              })
          .toList(),
    };
  }

  Future<Map<String, dynamic>> _respond(
      String requestId, bool accept, String? token) async {
    final me = await _donorUser(token);
    final myId = me['id'].toString();

    final all = await _loadRequests();
    final index = all.indexWhere((r) => r['id'] == requestId);
    if (index < 0) throw ApiException('Request not found.', 404);
    final request = all[index];

    final responses = await _loadResponses();
    if (responses.any((r) => r['requestId'] == requestId && r['donorId'] == myId)) {
      throw ApiException('You already responded to this request.', 409);
    }

    var nowMatched = false;
    if (accept) {
      final accepted = request['unitsAccepted'] as int;
      final needed = request['units'] as int;
      if (request['status'] != 'open' || accepted >= needed) {
        throw ApiException('This request is already covered.', 409);
      }
      request['unitsAccepted'] = accepted + 1;
      if (accepted + 1 >= needed) {
        request['status'] = 'matched';
        nowMatched = true;
      }
    }

    responses.add({
      'requestId': requestId,
      'donorId': myId,
      'donorName': me['name'],
      'phone': me['phone'],
      'status': accept ? 'accepted' : 'declined',
      'respondedAt': DateTime.now().toUtc().toIso8601String(),
    });
    await _saveRequests(all);
    await _saveResponses(responses);

    final requesterId = request['requesterId'].toString();
    if (accept) {
      await _notify(
        requesterId,
        type: 'accepted',
        title: '${me['name']} Accepted Your Request',
        message:
            'A donor will help at ${request['hospitalName']}. ${request['unitsAccepted']} of ${request['units']} units matched.',
        requestId: requestId,
      );
      if (nowMatched) {
        await _notify(
          requesterId,
          type: 'matched',
          title: 'All Units Matched',
          message:
              'Your request at ${request['hospitalName']} has enough donors. Mark it as fulfilled once the donation is complete.',
          requestId: requestId,
        );
      }
    }
    return {'request': request};
  }

  Future<Map<String, dynamic>> _donations(String? token) async {
    final me = await _donorUser(token);
    final all = await _loadRequests();
    final list = <Map<String, dynamic>>[];

    for (final r in await _loadResponses()) {
      if (r['donorId'] != me['id'].toString() || r['status'] != 'accepted') continue;
      final found = all.where((q) => q['id'] == r['requestId']);
      if (found.isEmpty) continue;
      final q = found.first;
      list.add({
        'requestId': q['id'],
        'hospitalName': q['hospitalName'],
        'bloodGroup': q['bloodGroup'],
        'city': q['city'],
        'units': q['units'],
        'status': q['status'],
        'date': r['respondedAt'],
      });
    }
    list.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return {'donations': list};
  }

  // ---------- donor profile ----------

  Map<String, dynamic> _donorView(Map<String, dynamic> me) => {
        'bloodGroup': me['bloodGroup'],
        'city': me['city'],
        'available': me['available'] ?? true,
        'lat': me['lat'],
        'lng': me['lng'],
        'age': me['age'],
        'weight': me['weight'],
        'hemoglobin': me['hemoglobin'],
        'daysSinceLastDonation': me['daysSinceLastDonation'],
      };

  Future<Map<String, dynamic>> _updateUser(
      String? token, Map<String, dynamic> changes) async {
    final me = await _donorUser(token);
    final users = await _loadUsers();
    final index =
        users.indexWhere((u) => u['id'].toString() == me['id'].toString());
    users[index].addAll(changes);
    await _saveUsers(users);
    return users[index];
  }

  Future<Map<String, dynamic>> _donorMe(String? token) async =>
      {'donor': _donorView(await _donorUser(token))};

  Future<Map<String, dynamic>> _setAvailability(
      Map<String, dynamic> b, String? token) async {
    final updated = await _updateUser(token, {'available': b['available'] == true});
    return {'donor': _donorView(updated)};
  }

  Future<Map<String, dynamic>> _updateLocation(
      Map<String, dynamic> b, String? token) async {
    if (b['lat'] is! num || b['lng'] is! num) {
      throw ApiException('lat and lng must be numbers.', 400);
    }
    final updated = await _updateUser(token, {'lat': b['lat'], 'lng': b['lng']});
    return {'donor': _donorView(updated)};
  }

  Future<Map<String, dynamic>> _saveHealth(
      Map<String, dynamic> b, String? token) async {
    num? n(dynamic v) => v is num ? v : num.tryParse('$v');
    final age = n(b['age']);
    final weight = n(b['weight']);
    final hemoglobin = n(b['hemoglobin']);
    final days = n(b['daysSinceLastDonation'] ?? b['days_since_last_donation']);
    if (age == null || weight == null || hemoglobin == null || days == null) {
      throw ApiException(
          'Age, weight, hemoglobin and days since last donation are required.',
          400);
    }
    final updated = await _updateUser(token, {
      'age': age,
      'weight': weight,
      'hemoglobin': hemoglobin,
      'daysSinceLastDonation': days,
    });
    return {'donor': _donorView(updated)};
  }

  // ---------- notifications ----------

  Future<Map<String, dynamic>> _notifications(String? token) async {
    final userId = _userId(token);
    final mine = (await _loadNotifications())
        .where((n) => n['userId'] == userId)
        .toList();
    return {'notifications': mine};
  }

  Future<Map<String, dynamic>> _readAll(String? token) async {
    final userId = _userId(token);
    final all = await _loadNotifications();
    for (final n in all) {
      if (n['userId'] == userId) n['read'] = true;
    }
    await _saveNotifications(all);
    return {'ok': true};
  }

  // ---------- sample data ----------

  List<Map<String, dynamic>> _seedUsers() => [
        {
          'id': '1',
          'name': 'Demo Donor',
          'email': 'donor@lifelink.test',
          'password': '123456',
          'phone': '9876543210',
          'city': 'Ghaziabad',
          'role': 'donor',
          'bloodGroup': 'O-',
        },
        {
          'id': '2',
          'name': 'Demo Requester',
          'email': 'requester@lifelink.test',
          'password': '123456',
          'phone': '9876500000',
          'city': 'Ghaziabad',
          'role': 'requester',
        },
      ];

  String _ago(int minutes) =>
      DateTime.now().toUtc().subtract(Duration(minutes: minutes)).toIso8601String();

  List<Map<String, dynamic>> _seedRequests() => [
        {
          'id': 'REQ-SEED-1',
          'requesterId': '2',
          'bloodGroup': 'O-',
          'units': 2,
          'unitsAccepted': 0,
          'hospitalName': 'Central City Trauma Center',
          'city': 'Ghaziabad',
          'urgency': 3,
          'status': 'open',
          'lat': 28.6692,
          'lng': 77.4538,
          'createdAt': _ago(14),
        },
        {
          'id': 'REQ-SEED-2',
          'requesterId': '2',
          'bloodGroup': 'A+',
          'units': 1,
          'unitsAccepted': 0,
          'hospitalName': 'Sunrise Medical Center',
          'city': 'Ghaziabad',
          'urgency': 2,
          'status': 'open',
          'lat': 28.6600,
          'lng': 77.4400,
          'createdAt': _ago(35),
        },
        {
          'id': 'REQ-SEED-3',
          'requesterId': '2',
          'bloodGroup': 'B+',
          'units': 3,
          'unitsAccepted': 3,
          'hospitalName': 'Lakeview General Hospital',
          'city': 'Ghaziabad',
          'urgency': 2,
          'status': 'fulfilled',
          'lat': 28.6700,
          'lng': 77.4300,
          'createdAt': _ago(1500),
        },
      ];

  List<Map<String, dynamic>> _seedResponses() => [
        {
          'requestId': 'REQ-SEED-3',
          'donorId': '1',
          'donorName': 'Demo Donor',
          'phone': '9876543210',
          'status': 'accepted',
          'respondedAt': _ago(1400),
        },
        {
          'requestId': 'REQ-SEED-3',
          'donorId': 'seed-a',
          'donorName': 'Aarav Sharma',
          'phone': '9810011223',
          'status': 'accepted',
          'respondedAt': _ago(1390),
        },
        {
          'requestId': 'REQ-SEED-3',
          'donorId': 'seed-b',
          'donorName': 'Priya Verma',
          'phone': '9810044556',
          'status': 'accepted',
          'respondedAt': _ago(1380),
        },
      ];

  List<Map<String, dynamic>> _seedNotifications() => [
        {
          'id': 'N-SEED-1',
          'userId': '1',
          'type': 'alert',
          'title': 'Critical O- Blood Alert Near You',
          'message':
              'Central City Trauma Center posted an emergency request for 2 units.',
          'requestId': 'REQ-SEED-1',
          'read': false,
          'createdAt': _ago(14),
        },
        {
          'id': 'N-SEED-2',
          'userId': '1',
          'type': 'alert',
          'title': 'New A+ Request Nearby',
          'message': 'Sunrise Medical Center posted an emergency request for 1 unit.',
          'requestId': 'REQ-SEED-2',
          'read': false,
          'createdAt': _ago(35),
        },
        {
          'id': 'N-SEED-3',
          'userId': '1',
          'type': 'fulfilled',
          'title': 'Request Fulfilled',
          'message':
              'The request at Lakeview General Hospital was fulfilled. Thank you for helping!',
          'requestId': 'REQ-SEED-3',
          'read': true,
          'createdAt': _ago(1380),
        },
        {
          'id': 'N-SEED-4',
          'userId': '2',
          'type': 'fulfilled',
          'title': 'Request Fulfilled',
          'message':
              'All 3 required units of B+ blood were matched at Lakeview General Hospital.',
          'requestId': 'REQ-SEED-3',
          'read': false,
          'createdAt': _ago(1380),
        },
      ];

  // ---------- storage (survives app restarts) ----------

  Future<List<Map<String, dynamic>>> _load(
      String key, List<Map<String, dynamic>> Function() seed) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) {
      final data = seed();
      await prefs.setString(key, jsonEncode(data));
      return data;
    }
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _save(String key, List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  Future<List<Map<String, dynamic>>> _loadUsers() => _load(_usersKey, _seedUsers);
  Future<void> _saveUsers(List<Map<String, dynamic>> d) => _save(_usersKey, d);

  Future<List<Map<String, dynamic>>> _loadRequests() =>
      _load(_requestsKey, _seedRequests);
  Future<void> _saveRequests(List<Map<String, dynamic>> d) => _save(_requestsKey, d);

  Future<List<Map<String, dynamic>>> _loadResponses() =>
      _load(_responsesKey, _seedResponses);
  Future<void> _saveResponses(List<Map<String, dynamic>> d) => _save(_responsesKey, d);

  Future<List<Map<String, dynamic>>> _loadNotifications() =>
      _load(_notificationsKey, _seedNotifications);
  Future<void> _saveNotifications(List<Map<String, dynamic>> d) =>
      _save(_notificationsKey, d);
}