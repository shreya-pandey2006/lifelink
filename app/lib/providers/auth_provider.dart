import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? user;
  bool initializing = true; // true while we check the saved token

  bool get isLoggedIn => user != null;

  AuthProvider() {
    // If the server ever says "401 not authenticated", log out automatically.
    ApiClient.instance.onUnauthorized = () {
      logout();
    };
  }

  // Runs once when the app starts: is there a saved token that still works?
  Future<void> init() async {
    final token = await TokenStorage.read();
    if (token != null) {
      ApiClient.instance.token = token;
      try {
        final data = await ApiClient.instance.get('/auth/me');
        user = AppUser.fromJson(_userMap(data));
      } catch (_) {
        await TokenStorage.clear();
        ApiClient.instance.token = null;
      }
    }
    initializing = false;
    notifyListeners();
  }

  // Each of these returns null on success, or an error message to show.
  Future<String?> login(String email, String password) {
    return _authenticate(() => ApiClient.instance.post('/auth/login', {
          'email': email.trim(),
          'password': password,
        }));
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String city,
    required String role,
    String? bloodGroup,
  }) {
    return _authenticate(() async {
      final data = await ApiClient.instance.post('/auth/register', {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'phone': phone.trim(),
        'city': city,
        'role': role,
        if (bloodGroup != null) 'bloodGroup': bloodGroup,
      });
      // If register does not return a token, log in right after.
      if (data is Map && data['token'] != null) return data;
      return ApiClient.instance.post('/auth/login', {
        'email': email.trim(),
        'password': password,
      });
    });
  }

  Future<String?> _authenticate(Future<dynamic> Function() call) async {
    try {
      final data = await call();
      final token = data['token']?.toString();
      if (token == null) return 'The server did not return a token.';

      final loggedIn = AppUser.fromJson(_userMap(data));
      if (loggedIn.isAdmin) {
        return 'Admin accounts must use the web dashboard.';
      }

      await TokenStorage.save(token);
      ApiClient.instance.token = token;
      user = loggedIn;
      notifyListeners(); // the router redirects to /home
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    ApiClient.instance.token = null;
    user = null;
    notifyListeners(); // the router redirects to /login
  }

  // Accepts either { user: {...} } or the user object directly.
  Map<String, dynamic> _userMap(dynamic data) {
    if (data is Map && data['user'] is Map) {
      return Map<String, dynamic>.from(data['user'] as Map);
    }
    return Map<String, dynamic>.from(data as Map);
  }
}