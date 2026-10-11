import 'package:shared_preferences/shared_preferences.dart';

// Saves the JWT on the phone so the user stays logged in.
class TokenStorage {
  static const _key = 'jwt_token';

  static Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}