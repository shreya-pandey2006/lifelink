import 'package:flutter/material.dart';
import '../models/donor_response_item.dart';
import '../services/api_client.dart';
import '../core/format.dart';

class DonorProvider extends ChangeNotifier {
  bool available = true;
  bool loaded = false;
  String? error;

  int? age;
  double? weightKg;
  double? hemoglobinGDl;
  int totalDonations = 0;
  DateTime? lastDonationDate;

  List<DonorResponseItem> myResponses = [];
  bool loadingResponses = false;

  Future<void> load() async {
    try {
      final data = await ApiClient.instance.get('/donors/me');
      final donor = extractMap(data, ['donor', 'profile']);
      available = donor['available'] != false;
      age = donor['age'] is num ? (donor['age'] as num).toInt() : int.tryParse('${donor['age']}');
      weightKg = donor['weightKg'] is num ? (donor['weightKg'] as num).toDouble() : double.tryParse('${donor['weightKg']}');
      hemoglobinGDl = donor['hemoglobinGDl'] is num
          ? (donor['hemoglobinGDl'] as num).toDouble()
          : double.tryParse('${donor['hemoglobinGDl']}');
      totalDonations = donor['totalDonations'] is num
          ? (donor['totalDonations'] as num).toInt()
          : (int.tryParse('${donor['totalDonations']}') ?? 0);
      lastDonationDate = DateTime.tryParse((donor['lastDonationDate'] ?? '').toString())?.toLocal();
      loaded = true;
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    }
    notifyListeners();
  }
  Future<String?> setAvailable(bool value) async {
    final previous = available;
    available = value;
    notifyListeners();
    try {
      await ApiClient.instance.patch('/donors/availability', {'available': value});
      return null;
    } on ApiException catch (e) {
      available = previous;
      notifyListeners();
      return e.message;
    } catch (_) {
      available = previous;
      notifyListeners();
      return 'Something went wrong. Please try again.';
    }
  }
  Future<String?> saveMlDetails({
    required num age,required num weightKg,required num hemoglobinGDl,
  }) async {
    try {
      final data = await ApiClient.instance.patch('/donors/ml-details', {
        'age': age,'weightKg': weightKg,'hemoglobinGDl': hemoglobinGDl,
      });
      final donor = extractMap(data, ['donor']);
      this.age = donor['age'] is num ? (donor['age'] as num).toInt() : age.toInt();
      this.weightKg = donor['weightKg'] is num ? (donor['weightKg'] as num).toDouble() : weightKg.toDouble();
      this.hemoglobinGDl = donor['hemoglobinGDl'] is num ? (donor['hemoglobinGDl'] as num).toDouble() : hemoglobinGDl.toDouble();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }
  Future<void> loadMyResponses({bool silent = false}) async {
    if (!silent) {
      loadingResponses = true;
      notifyListeners();
    }
    try {
      final data = await ApiClient.instance.get('/responses/my');
      final list = extractList(data, ['responses']);
      myResponses = list.map((e) => DonorResponseItem.fromJson(asMap(e))).toList();
    } catch (_) {}
    loadingResponses = false;
    notifyListeners();
  }
  Future<String?> respondToRequest(
    String requestId, {
    required bool accept, String message = '',
  }) async {
    try {
      await ApiClient.instance.post('/responses/$requestId', {
        'status': accept ? 'accepted' : 'declined',
        if (message.isNotEmpty) 'message': message.trim(),
      });
      await loadMyResponses(silent: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to save response. Please try again.';
    }
  }

  void clear() {
    available = true;
    loaded = false;
    error = null;
    age = null;
    weightKg = null;
    hemoglobinGDl = null;
    totalDonations = 0;
    lastDonationDate = null;
    myResponses = [];
    loadingResponses = false;
    notifyListeners();
  }
}