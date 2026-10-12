import 'package:flutter/material.dart';
import '../models/blood_request.dart';
import '../services/api_client.dart';
class RequestProvider extends ChangeNotifier {
  List<BloodRequest> requests = [];
  bool loading = false;
  String? error;
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final data = await ApiClient.instance.get('/requests');
      final list = (data is Map ? data['requests'] : data) as List? ?? [];
      requests = list
          .map((e) => BloodRequest.fromJson(Map<String, dynamic>.from(e as Map)))
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
  Future<BloodRequest> create({
    required String bloodGroup, required int units, required String hospitalName,
    required String city, required int urgency, double? lat, double? lng,
  }) async {
    final data = await ApiClient.instance.post('/requests', {
      'bloodGroup': bloodGroup, 'units': units, 'hospitalName': hospitalName.trim(), 'city': city, 'urgency': urgency, 'lat': ?lat, 'lng': ?lng,
    });
    final map = (data is Map && data['request'] is Map)
        ? Map<String, dynamic>.from(data['request'] as Map)
        : Map<String, dynamic>.from(data as Map);
    final request = BloodRequest.fromJson(map);
    requests = [request, ...requests];
    notifyListeners();
    return request;
  }
  void clear() {
    requests = [];
    error = null;
    loading = false;
    notifyListeners();
  }
}