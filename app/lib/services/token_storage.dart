import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _key = 'jwt_token';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Reads token securely from FlutterSecureStorage.
  /// Falls back to SharedPreferences to migrate any legacy token.
  static Future<String?> read() async {
    try {
      final token = await _storage.read(key: _key);
      if (token != null && token.isNotEmpty) {
        return token;
      }

      // Check legacy SharedPreferences and migrate if present
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(_key);
      if (legacyToken != null && legacyToken.isNotEmpty) {
        await _storage.write(key: _key, value: legacyToken);
        await prefs.remove(_key);
        return legacyToken;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Securely saves the token using FlutterSecureStorage and removes any legacy plaintext copy.
  static Future<void> save(String token) async {
    await _storage.write(key: _key, value: token);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  /// Deletes the token from FlutterSecureStorage and SharedPreferences.
  static Future<void> clear() async {
    await _storage.delete(key: _key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}