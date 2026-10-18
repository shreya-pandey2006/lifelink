import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';
import '../core/format.dart';
class AuthProvider extends ChangeNotifier {
  AppUser? user;
  bool initializing = true;
  bool get isLoggedIn => user != null;

  AuthProvider() {
    ApiClient.instance.onUnauthorized = () {
      logout();
    };
  }
  Future<void> init() async {
    try {
      final token = await TokenStorage.read();
      if (token != null) {
        ApiClient.instance.token = token;
        try {
          user = await _loadFullUser();
        } catch (_) {
          await TokenStorage.clear();
          ApiClient.instance.token = null;
        }
      }
    } catch (e) {
      debugPrint('Auth init failed: $e');
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) {
    return _authenticate(() => ApiClient.instance.post('/auth/login', {
          'email': email.trim().toLowerCase(),
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
      await ApiClient.instance.post('/auth/register', {
        'name': name.trim(), 'email': email.trim().toLowerCase(), 'password': password, 'phone': phone.trim(), 'city': city.trim(), 'role': role,
        if (role == 'donor' && bloodGroup != null) 'bloodGroup': bloodGroup,
      });
      return ApiClient.instance.post('/auth/login', {
        'email': email.trim().toLowerCase(), 'password': password,
      });
    });
  }

  Future<String?> _authenticate(Future<dynamic> Function() call) async {
    try {
      final data = await call();
      final m = asMap(data);
      final inner = asMap(m['data']);
      final token = (m['token'] ?? m['accessToken'] ?? inner['token'] ?? inner['accessToken'])
          ?.toString();
      if (token == null) return 'The server did not return a token.';
      final loggedIn = AppUser.fromJson(_userMap(data));
      if (loggedIn.isAdmin) {
        return 'Admin accounts must use the web dashboard.';
      }
      await TokenStorage.save(token);
      ApiClient.instance.token = token;
      user = await _loadFullUser(fallback: loggedIn);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Map<String, dynamic> _userMap(dynamic data) => extractMap(data, ['user']);
  Future<AppUser> _loadFullUser({AppUser? fallback}) async {
    try {
      final me = await ApiClient.instance.get('/auth/me');
      var u = AppUser.fromJson(extractMap(me, ['user']));
      if (u.isDonor) {
        try {
          final d = await ApiClient.instance.get('/donors/me');
          final donorData = extractMap(d, ['donor']);
          final bg = donorData['bloodGroup']?.toString();
          u = AppUser(
            id: u.id,
            name: u.name,
            email: u.email,
            role: u.role,
            phone: u.phone,
            city: u.city,
            bloodGroup: bg ?? u.bloodGroup,
          );
        } catch (_) {}
      }
      return u;
    } catch (_) {
      if (fallback != null) return fallback;
      rethrow;
    }
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    ApiClient.instance.token = null;
    user = null;
    notifyListeners();
  }
}