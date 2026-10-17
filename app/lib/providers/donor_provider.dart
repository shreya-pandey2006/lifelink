import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  int totalDonations = 0;
  String? bloodGroup;
  String? city;
  DateTime? lastDonationDate;

  bool get hasLocation => lat != null && lng != null;
  bool get hasHealthDetails =>
      age != null && weight != null && hemoglobin != null;

  Future<void> load() async {
    try {
      final data = await ApiClient.instance.get('/donors/me');
      final donor = (data is Map && data['donor'] is Map)
          ? data['donor'] as Map
          : data as Map;
      available = donor['available'] != false;
      age = donor['age'] == null ? null : asInt(donor['age'], 0);
      weight = asDouble(donor['weightKg'] ?? donor['weight']);
      hemoglobin = asDouble(donor['hemoglobinGDl'] ?? donor['hemoglobin']);
      totalDonations = asInt(donor['totalDonations'], 0);
      bloodGroup = donor['bloodGroup']?.toString();
      city = donor['city']?.toString();

      if (donor['lastDonationDate'] != null) {
        lastDonationDate =
            DateTime.tryParse(donor['lastDonationDate'].toString())?.toLocal();
        if (lastDonationDate != null) {
          daysSinceLastDonation =
              DateTime.now().difference(lastDonationDate!).inDays;
        }
      }
      if (daysSinceLastDonation == null) {
        final days = donor['daysSinceLastDonation'] ??
            donor['days_since_last_donation'];
        if (days != null) {
          daysSinceLastDonation = asInt(days, 0);
        }
      }

      final prefs = await SharedPreferences.getInstance();
      lat ??= prefs.getDouble('donor_lat');
      lng ??= prefs.getDouble('donor_lng');

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
          .patch('/donors/availability', {'available': value});
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
    lat = newLat;
    lng = newLng;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('donor_lat', newLat);
      await prefs.setDouble('donor_lng', newLng);
      try {
        await ApiClient.instance
            .put('/donors/me', {'lat': newLat, 'lng': newLng});
      } catch (_) {}
      return null;
    } catch (_) {
      return 'Could not save location.';
    }
  }

  Future<String?> saveHealth({
    required int age,
    required double weight,
    required double hemoglobin,
    int? daysSinceLastDonation,
  }) async {
    try {
      await ApiClient.instance.patch('/donors/ml-details', {
        'age': age,
        'weightKg': weight,
        'hemoglobinGDl': hemoglobin,
      });
      this.age = age;
      this.weight = weight;
      this.hemoglobin = hemoglobin;
      if (daysSinceLastDonation != null) {
        this.daysSinceLastDonation = daysSinceLastDonation;
      }
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
    totalDonations = 0;
    bloodGroup = null;
    city = null;
    lastDonationDate = null;
    notifyListeners();
  }
}