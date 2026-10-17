import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/api_client.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> items = [];
  bool loading = false;
  bool unsupported = false;
  String? error;

  int get unread => items.where((n) => !n.read).length;

  Future<void> load({bool silent = true}) async {
    if (unsupported && silent) return;
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final data = await ApiClient.instance.get('/notifications');
      final list =
          (data is Map ? (data['notifications'] ?? data['data']) : data) as List? ??
              [];
      items = list
          .map((e) =>
              AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      unsupported = false;
      error = null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        unsupported = true;
      } else {
        error = e.message;
      }
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    if (unread == 0) return;
    items = items.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
    try {
      await ApiClient.instance.patch('/notifications/read-all');
    } catch (_) {}
  }

  void clear() {
    items = [];
    loading = false;
    unsupported = false;
    error = null;
    notifyListeners();
  }
}