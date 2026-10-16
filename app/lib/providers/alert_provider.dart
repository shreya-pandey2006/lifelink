import 'package:flutter/material.dart';
import '../models/alert_item.dart';
import '../services/api_client.dart';
class AlertProvider extends ChangeNotifier {
  List<AlertItem> alerts = [];
  bool loading = false;
  String? error;
  int get criticalCount => alerts.where((a) => a.isCritical).length;
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final data = await ApiClient.instance.get('/alerts');
      final list = (data is Map ? data['alerts'] : data) as List? ?? [];
      alerts = list
          .map((e) => AlertItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    }
    loading = false;
    notifyListeners();
  }
  Future<String?> respond(String requestId, bool accept) async {
    try {
      await ApiClient.instance
          .post('/responses/$requestId/${accept ? 'accept' : 'decline'}');
      alerts = alerts.where((a) => a.requestId != requestId).toList();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        alerts = alerts.where((a) => a.requestId != requestId).toList();
        notifyListeners();
      }
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }
  void clear() {
    alerts = [];
    error = null;
    loading = false;
    notifyListeners();
  }
}