import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifelink_app/services/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('TokenStorage', () {
    test('save and read token from secure storage', () async {
      expect(await TokenStorage.read(), isNull);

      await TokenStorage.save('jwt-secure-test-token');
      final token = await TokenStorage.read();

      expect(token, 'jwt-secure-test-token');
    });

    test('clear removes token from secure storage', () async {
      await TokenStorage.save('jwt-secure-test-token');
      expect(await TokenStorage.read(), 'jwt-secure-test-token');

      await TokenStorage.clear();
      expect(await TokenStorage.read(), isNull);
    });

    test('migrates legacy token from SharedPreferences to secure storage', () async {
      // Simulate legacy token in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', 'legacy-prefs-token');

      // FlutterSecureStorage has nothing initially
      FlutterSecureStorage.setMockInitialValues({});

      // Reading should retrieve and migrate it
      final token = await TokenStorage.read();
      expect(token, 'legacy-prefs-token');

      // Verify SharedPreferences legacy key is cleaned up
      expect(prefs.getString('jwt_token'), isNull);

      // Verify it is now read directly from secure storage
      expect(await TokenStorage.read(), 'legacy-prefs-token');
    });

    test('save clears any legacy token in SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', 'old-prefs-token');

      await TokenStorage.save('brand-new-secure-token');

      expect(prefs.getString('jwt_token'), isNull);
      expect(await TokenStorage.read(), 'brand-new-secure-token');
    });
  });
}
