import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifelink_app/models/app_notification.dart';
import 'package:lifelink_app/providers/notification_provider.dart';
import 'package:lifelink_app/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.token = 'test-token';
    ApiClient.instance.client = MockClient((request) async {
      final path = request.url.path;

      if (request.method == 'GET' && path.endsWith('/notifications/unread-count')) {
        return http.Response(jsonEncode({'success': true, 'unreadCount': 5}), 200);
      }

      if (request.method == 'GET' && path.endsWith('/notifications')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'notifications': [
              {
                '_id': 'notif-1',
                'type': 'emergency',
                'title': 'Emergency Alert',
                'message': 'Need A+ blood',
                'isRead': false,
                'relatedRequest': 'req-123',
                'createdAt': DateTime.now().toIso8601String(),
              },
              {
                '_id': 'notif-2',
                'type': 'general',
                'title': 'Update',
                'message': 'Profile verified',
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

      if (request.method == 'DELETE' && path.contains('/notifications/')) {
        return http.Response(jsonEncode({'success': true}), 200);
      }

      return http.Response(jsonEncode({'message': 'Not found'}), 404);
    });
  });

  group('NotificationProvider Tests', () {
    test('initial state has 0 items and 0 unread', () {
      final provider = NotificationProvider();
      expect(provider.items, isEmpty);
      expect(provider.unread, 0);
      expect(provider.loading, false);
      expect(provider.error, isNull);
    });

    test('fetchUnreadCount updates server unread count', () async {
      final provider = NotificationProvider();
      await provider.fetchUnreadCount();
      expect(provider.unread, 5);
    });

    test('load fetches notifications and parses response correctly', () async {
      final provider = NotificationProvider();
      await provider.load(silent: false);

      expect(provider.items.length, 2);
      expect(provider.items[0].id, 'notif-1');
      expect(provider.items[0].type, 'emergency');
      expect(provider.items[0].requestId, 'req-123');
      expect(provider.items[0].read, false);
      expect(provider.items[1].read, true);
      expect(provider.unread, 1);
    });

    test('markAsRead updates item optimistically and calls API', () async {
      final provider = NotificationProvider();
      final item = AppNotification(
        id: 'notif-1',
        type: 'emergency',
        title: 'Emergency Request',
        message: 'O- needed urgently',
        read: false,
      );
      provider.items = [item];
      expect(provider.unread, 1);

      final success = await provider.markAsRead('notif-1');
      expect(success, true);
      expect(provider.items.first.read, true);
      expect(provider.unread, 0);
    });

    test('markAllRead marks all items read and zeroes unread', () async {
      final provider = NotificationProvider();
      provider.items = [
        const AppNotification(
          id: '1',
          type: 'emergency',
          title: 'Alert 1',
          message: 'Message 1',
          read: false,
        ),
        const AppNotification(
          id: '2',
          type: 'general',
          title: 'Alert 2',
          message: 'Message 2',
          read: false,
        ),
      ];
      expect(provider.unread, 2);

      final success = await provider.markAllRead();
      expect(success, true);
      expect(provider.items.every((n) => n.read), true);
      expect(provider.unread, 0);
    });

    test('deleteNotification removes item and decrements unread', () async {
      final provider = NotificationProvider();
      provider.items = [
        const AppNotification(
          id: 'del-1',
          type: 'blood_request',
          title: 'Blood Request',
          message: 'Need blood',
          read: false,
        ),
      ];
      expect(provider.unread, 1);

      final success = await provider.deleteNotification('del-1');
      expect(success, true);
      expect(provider.items, isEmpty);
      expect(provider.unread, 0);
    });

    test('clear resets all provider state', () {
      final provider = NotificationProvider();
      provider.items = [
        const AppNotification(
          id: '1',
          type: 'general',
          title: 'General',
          message: 'Message',
          read: false,
        ),
      ];
      provider.clear();
      expect(provider.items, isEmpty);
      expect(provider.unread, 0);
      expect(provider.loading, false);
      expect(provider.error, isNull);
    });
  });
}
