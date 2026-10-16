import 'package:flutter/material.dart';
import '../models/donation.dart';
import '../services/api_client.dart';
class HistoryProvider extends ChangeNotifier {
  List<Donation> items = [];
  bool loading = false;
  String? error;
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await ApiClient.instance.get('/donations/me');
      final list =  (data is Map ? (data['donations'] ?? data['data']) : data) as List? ?? [];
      items = list
          .map((e) => Donation.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    }
    loading = false;
    notifyListeners();
  }
  void clear() {
    items = [];
    loading = false;
    error = null;
    notifyListeners();
  }
}