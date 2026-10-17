import 'package:flutter/material.dart';
import '../models/blood_request.dart';
import '../models/potential_donor.dart';
import '../services/api_client.dart';
import '../core/format.dart';

class RequestProvider extends ChangeNotifier {
  List<BloodRequest> requests = [];
  int availableDonorCount = 0;
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
      final list = extractList(data, ['bloodRequests', 'requests']);
      requests = list
          .map((e) => BloodRequest.fromJson(asMap(e)))
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

  static String mapUrgency(int urgency) {
    switch (urgency) {
      case 3:
        return 'emergency';
      case 2:
        return 'urgent';
      default:
        return 'normal';
    }
  }

  Future<BloodRequest> create({
    required String bloodGroup,
    required int units,
    required String hospitalName,
    required String city,
    required int urgency,
    double? lat,
    double? lng,
  }) async {
    final data = await ApiClient.instance.post('/requests', {
      'bloodGroup': bloodGroup,
      'city': city.trim(),
      'units': units,
      'urgency': mapUrgency(urgency),
      if (hospitalName.trim().isNotEmpty) 'hospital': hospitalName.trim(),
      'lat': ?lat,
      'lng': ?lng,
    });
    final map = extractMap(data, ['bloodRequest', 'request']);
    final request = BloodRequest.fromJson(map);
    requests = [request, ...requests];
    notifyListeners();
    return request;
  }

  Future<List<PotentialDonor>> getPotentialDonors(String requestId) async {
    try {
      final data = await ApiClient.instance.get('/requests/$requestId/potential-donors');
      final list = extractList(data, ['potentialDonors']);
      return list.map((e) => PotentialDonor.fromJson(asMap(e))).toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Failed to load matching donors.');
    }
  }

  Future<int> fetchAvailableDonorCount() async {
    try {
      final data = await ApiClient.instance.get('/donors/available/count');
      final m = asMap(data);
      availableDonorCount = asInt(m['availableDonorCount'], 0);
      notifyListeners();
      return availableDonorCount;
    } catch (_) {
      return availableDonorCount;
    }
  }

  void clear() {
    requests = [];
    availableDonorCount = 0;
    error = null;
    loading = false;
    notifyListeners();
  }

  Future<String?> saveMlDetails({
    required num age,
    required num weightKg,
    required num hemoglobinGDl,
  }) async {
    try {
      await ApiClient.instance.patch('/donors/ml-details', {
        'age': age,
        'weightKg': weightKg,
        'hemoglobinGDl': hemoglobinGDl,
      });
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> respondToRequest(
    String requestId, {
    required bool accept,
    String? message,
  }) async {
    try {
      await ApiClient.instance.post('/responses/$requestId', {
        'status': accept ? 'accepted' : 'declined',
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      });
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }
}