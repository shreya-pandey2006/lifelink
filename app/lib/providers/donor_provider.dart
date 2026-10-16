import 'package:flutter/material.dart';
import '../core/format.dart';
import '../services/api_client.dart';
class DonorProvider extends ChangeNotifier {
  bool available = true;
  bool loaded = false;
  String? error;
  double? lat;
  double? lng;
  int? age;
  double? weight;
  double? hemoglobin;
  int? daysSinceLastDonation;
  bool get hasLocation => lat != null && lng != null;
  bool get hasHealthDetails => age != null && weight != null && hemoglobin != null && daysSinceLastDonation != null;
  Future<void> load() async {
    try {
      final data = await ApiClient.instance.get('/donors/me');
      final donor = (data is Map && data['donor'] is Map) ? data['donor'] as Map : data as Map;
      available = donor['available'] != false;
      lat = asDouble(donor['lat']);
      lng = asDouble(donor['lng']);
      age = donor['age'] == null ? null : asInt(donor['age'], 0);
      weight = asDouble(donor['weight']);
      hemoglobin = asDouble(donor['hemoglobin']);
      final days = donor['daysSinceLastDonation'] ?? donor['days_since_last_donation'];
      daysSinceLastDonation = days == null ? null : asInt(days, 0);
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
      await ApiClient.instance
          .patch('/donors/me/availability', {'available': value});
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
  Future<String?> updateLocation(double newLat, double newLng) async {
    try {
      await ApiClient.instance.put('/donors/me', {'lat': newLat, 'lng': newLng});
      lat = newLat;
      lng = newLng;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }
  Future<String?> saveHealth({
    required int age, required double weight, required double hemoglobin, required int daysSinceLastDonation,
  }) async {
    try {
      await ApiClient.instance.patch('/donors/ml-details', { 
        'age': age, 'weight': weight, 'hemoglobin': hemoglobin, 'daysSinceLastDonation': daysSinceLastDonation, 'days_since_last_donation': daysSinceLastDonation,
        });
      this.age = age;
      this.weight = weight;
      this.hemoglobin = hemoglobin;
      this.daysSinceLastDonation = daysSinceLastDonation;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }
  void clear() {
    available = true;
    loaded = false;
    error = null;
    lat = null;
    lng = null;
    age = null;
    weight = null;
    hemoglobin = null;
    daysSinceLastDonation = null;
    notifyListeners();
  }
}