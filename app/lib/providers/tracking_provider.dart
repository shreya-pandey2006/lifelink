import 'package:flutter/material.dart';
import '../models/blood_request.dart';
import '../models/responder.dart';
import '../services/api_client.dart';
class TrackingProvider extends ChangeNotifier {
  BloodRequest? request;
  List<Responder> responders = [];
  bool loading = false;
  String? error;
  bool limited = false; 
  Future<void> load(String id, {bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final data = await ApiClient.instance.get('/requests/$id');
      final map = data as Map;
      final requestMap = map['request'] is Map
          ? Map<String, dynamic>.from(map['request'] as Map)
          : Map<String, dynamic>.from(map);
      request = BloodRequest.fromJson(requestMap);
      final list = (map['responses'] ?? map['responders']) as List? ?? [];
      responders = list
          .map((e) => Responder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      limited = false;
      error = null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        await _loadFallback(id);
      } else {
        error = e.message;
      }
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    }
    loading = false;
    notifyListeners();
  }
  Future<void> _loadFallback(String id) async {
    try {
      final data = await ApiClient.instance.get('/requests');
      final list = (data is Map
              ? (data['bloodRequests'] ?? data['requests'] ?? data['data'])
              : data) as List? ??
          [];
      final matches = list
          .map((e) => BloodRequest.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((r) => r.id == id);
      if (matches.isEmpty) {
        error = 'This request was not found.';
        return;
      }
      request = matches.first;
      limited = true;
      error = null;
      try {
        final pd =
            await ApiClient.instance.get('/requests/$id/potential-donors');
        final donors = (pd is Map
                ? (pd['potentialDonors'] ?? pd['donors'] ?? pd['data'])
                : pd) as List? ??
            [];
        responders = donors
            .map((e) => Responder.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        responders = [];
      }
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    }
  }

  Future<String?> setStatus(String id, String status) async {
    try {
      await ApiClient.instance
          .patch('/admin/requests/$id/status', {'status': status});
      await load(id, silent: true);
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.statusCode == 404) {
        return 'Request status updates are managed by the matching workflow.';
      }
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  void clear() {
    request = null;
    responders = [];
    loading = false;
    error = null;
    limited = false;
    notifyListeners();
  }
}