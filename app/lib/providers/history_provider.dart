import 'package:flutter/material.dart';
import '../models/donation.dart';
import '../services/api_client.dart';

class HistoryProvider extends ChangeNotifier {
  List<Donation> items = [];
  bool loading = false;
  String? error;
  int total = 0;

  Future<void> load({int page = 1, int limit = 50}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data =
          await ApiClient.instance.get('/responses/my?page=$page&limit=$limit');
      final list = (data is Map
              ? (data['responses'] ?? data['donations'] ?? data['data'])
              : data) as List? ??
          [];
      items = list
          .map((e) => Donation.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      total = data is Map && data['total'] is num
          ? (data['total'] as num).toInt()
          : items.length;
      error = null;
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
    total = 0;
    notifyListeners();
  }
}