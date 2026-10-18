import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/api_client.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> items = [];
  bool loading = false;
  bool loadingMore = false;
  bool unsupported = false;
  String? error;

  int? _serverUnreadCount;
  int currentPage = 1;
  int totalPages = 1;
  int totalCount = 0;
  bool hasMore = true;

  int get unread => _serverUnreadCount ?? items.where((n) => !n.read).length;

  /// Fetches unread notification count from GET /api/notifications/unread-count.
  /// Used for lightweight periodic updates on badge indicators.
  Future<void> fetchUnreadCount() async {
    try {
      final data = await ApiClient.instance.get('/notifications/unread-count');
      if (data is Map && data['unreadCount'] != null) {
        _serverUnreadCount = (data['unreadCount'] as num).toInt();
        notifyListeners();
      }
    } catch (_) {
      // Gracefully ignore network errors during background badge polling
    }
  }

  /// Loads notifications from GET /api/notifications with pagination support.
  Future<void> load({
    bool silent = true,
    bool refresh = false,
    int page = 1,
    int limit = 10,
  }) async {
    if (unsupported && silent) return;

    if (refresh) {
      page = 1;
      hasMore = true;
    }

    final isNextPage = page > 1;

    if (isNextPage) {
      if (loadingMore || !hasMore) return;
      loadingMore = true;
      notifyListeners();
    } else {
      if (!silent) {
        loading = true;
        error = null;
        notifyListeners();
      }
    }

    try {
      final data = await ApiClient.instance.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final list = (data is Map
              ? (data['notifications'] ?? data['data'])
              : data) as List? ??
          [];

      final newItems = list
          .map((e) =>
              AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (data is Map && data['pagination'] is Map) {
        final p = Map<String, dynamic>.from(data['pagination'] as Map);
        currentPage = (p['page'] as num?)?.toInt() ?? page;
        totalPages = (p['pages'] as num?)?.toInt() ?? 1;
        totalCount = (p['total'] as num?)?.toInt() ?? newItems.length;
        hasMore = currentPage < totalPages && newItems.isNotEmpty;
      } else {
        currentPage = page;
        hasMore = newItems.length >= limit;
      }

      if (isNextPage) {
        items.addAll(newItems);
      } else {
        items = newItems;
      }

      // Sync unread count
      final localUnread = items.where((n) => !n.read).length;
      if (_serverUnreadCount == null || !isNextPage) {
        _serverUnreadCount = localUnread;
      }

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
    loadingMore = false;
    notifyListeners();
  }

  /// Loads next page of notifications.
  Future<void> loadMore({int limit = 10}) async {
    if (loading || loadingMore || !hasMore) return;
    await load(silent: true, page: currentPage + 1, limit: limit);
  }

  /// Marks a single notification as read: PATCH /api/notifications/:id/read
  Future<bool> markAsRead(String id) async {
    final index = items.indexWhere((n) => n.id == id);
    if (index < 0) return false;
    final item = items[index];
    if (item.read) return true;

    // Optimistic update
    items[index] = item.copyWith(read: true);
    if (_serverUnreadCount != null && _serverUnreadCount! > 0) {
      _serverUnreadCount = _serverUnreadCount! - 1;
    }
    notifyListeners();

    try {
      await ApiClient.instance.patch('/notifications/$id/read');
      return true;
    } catch (_) {
      // Revert optimistic update on failure
      items[index] = item;
      if (_serverUnreadCount != null) {
        _serverUnreadCount = _serverUnreadCount! + 1;
      }
      notifyListeners();
      return false;
    }
  }

  /// Marks all notifications as read: PATCH /api/notifications/read-all
  Future<bool> markAllRead() async {
    if (unread == 0) return true;

    final backup = List<AppNotification>.from(items);
    final previousUnread = _serverUnreadCount;

    // Optimistic update
    items = items.map((n) => n.copyWith(read: true)).toList();
    _serverUnreadCount = 0;
    notifyListeners();

    try {
      await ApiClient.instance.patch('/notifications/read-all');
      return true;
    } catch (_) {
      // Revert optimistic update on failure
      items = backup;
      _serverUnreadCount = previousUnread;
      notifyListeners();
      return false;
    }
  }

  /// Deletes a notification: DELETE /api/notifications/:id
  Future<bool> deleteNotification(String id) async {
    final index = items.indexWhere((n) => n.id == id);
    if (index < 0) return false;

    final removed = items[index];

    // Optimistic removal
    items.removeAt(index);
    if (!removed.read && _serverUnreadCount != null && _serverUnreadCount! > 0) {
      _serverUnreadCount = _serverUnreadCount! - 1;
    }
    notifyListeners();

    try {
      await ApiClient.instance.delete('/notifications/$id');
      return true;
    } catch (_) {
      // Revert removal on failure
      items.insert(index, removed);
      if (!removed.read && _serverUnreadCount != null) {
        _serverUnreadCount = _serverUnreadCount! + 1;
      }
      notifyListeners();
      return false;
    }
  }

  void clear() {
    items = [];
    loading = false;
    loadingMore = false;
    unsupported = false;
    error = null;
    _serverUnreadCount = 0;
    currentPage = 1;
    totalPages = 1;
    totalCount = 0;
    hasMore = true;
    notifyListeners();
  }
}