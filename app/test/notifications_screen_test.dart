import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifelink_app/providers/auth_provider.dart';
import 'package:lifelink_app/providers/notification_provider.dart';
import 'package:lifelink_app/screens/notifications/notifications_screen.dart';
import 'package:lifelink_app/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.token = 'test-token';
    ApiClient.instance.client = MockClient((request) async {
      final path = request.url.path;

      if (request.method == 'GET' && path.endsWith('/notifications/unread-count')) {
        return http.Response(jsonEncode({'success': true, 'unreadCount': 1}), 200);
      }

      if (request.method == 'GET' && path.endsWith('/notifications')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'notifications': [
              {
                '_id': 'notif-emergency',
                'type': 'emergency',
                'title': 'Emergency Alert',
                'message': 'Need A+ blood urgently',
                'isRead': false,
                'relatedRequest': 'req-999',
                'createdAt': DateTime.now().toIso8601String(),
              },
              {
                '_id': 'notif-general',
                'type': 'general',
                'title': 'System Update',
                'message': 'Maintenance finished',
                'isRead': true,
                'createdAt': DateTime.now().toIso8601String(),
              }
            ],
            'pagination': {'page': 1, 'pages': 1, 'total': 2}
          }),
          200,
        );
      }

      if (request.method == 'PATCH' && path.contains('/read')) {
        return http.Response(jsonEncode({'success': true}), 200);
      }

      if (request.method == 'DELETE') {
        return http.Response(jsonEncode({'success': true}), 200);
      }

      return http.Response(jsonEncode({'message': 'Not found'}), 404);
    });
  });

  testWidgets('NotificationsScreen renders items, marks read, and deletes',
      (tester) async {
    final notifProvider = NotificationProvider();
    final authProvider = AuthProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<NotificationProvider>.value(
              value: notifProvider),
        ],
        child: const MaterialApp(
          home: NotificationsScreen(),
        ),
      ),
    );

    // Initial pump and fetch
    await tester.pumpAndSettle();

    // Verify screen title
    expect(find.text('Emergency Notifications'), findsOneWidget);

    // Verify items are displayed
    expect(find.text('Emergency Alert'), findsOneWidget);
    expect(find.text('System Update'), findsOneWidget);
    expect(find.text('EMERGENCY REQUEST'), findsOneWidget);
    expect(find.text('NOTIFICATION'), findsOneWidget);

    // Verify mark all read button is visible since 1 item is unread
    expect(find.text('Mark all read'), findsOneWidget);

    // Tap Mark all read
    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    // After mark all read, all are read, so Mark all read button disappears
    expect(find.text('Mark all read'), findsNothing);

    // Swipe to delete the emergency item
    await tester.drag(find.text('Emergency Alert'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Verify deleted
    expect(find.text('Emergency Alert'), findsNothing);
    expect(find.text('System Update'), findsOneWidget);
  });
}
