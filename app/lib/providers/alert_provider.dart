import 'package:flutter/material.dart';
import '../models/alert_item.dart';
import '../services/api_client.dart';
import '../core/format.dart';
class AlertProvider extends ChangeNotifier {
  List<AlertItem> alerts = [];
  bool loading = false;
  String? error;
  int get criticalCount => alerts.where((a) => a.isCritical).length;
    bool unavailable = false;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final data = await ApiClient.instance.get('/alerts');
      final list = extractList(data, ['alerts']);
      alerts = list
          .map((e) => AlertItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      error = null;
      unavailable = false;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        alerts = [];
        error = null;
        unavailable = true; // backend has no /alerts yet
      } else {
        error = e.message;
      }
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    }
    loading = false;
    notifyListeners();
  }
  void clear() {
    alerts = [];
    error = null;
    loading = false;
    notifyListeners();
  }
}