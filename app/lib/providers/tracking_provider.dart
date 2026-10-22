import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/format.dart';
import '../models/blood_request.dart';
import '../models/potential_donor.dart';
import '../models/responder.dart';
import '../services/api_client.dart';

double maxRadiusKmForUrgency(int urgency) {
  switch (urgency) {
    case 3:
      return 5.0; // Critical: 5 km
    case 2:
      return 10.0; // Urgent: 10 km
    case 1:
    default:
      return 20.0; // Normal: 20 km
  }
}

double calculateDistanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180.0;
  final dLng = (lng2 - lng1) * math.pi / 180.0;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180.0) *
          math.cos(lat2 * math.pi / 180.0) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

class TrackingProvider extends ChangeNotifier {
  BloodRequest? request;
  List<Responder> responders = [];
  List<PotentialDonor> availableDonors = [];
  bool loading = false;
  bool loadingAvailableDonors = false;
  String? error;
  bool limited = false;
  double? maxRadiusKm;

  Future<void> load(String id, {bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final data = await ApiClient.instance.get('/requests/$id');
      final map = asMap(data);
      final requestMap = extractMap(map, ['bloodRequest', 'request']);
      request = BloodRequest.fromJson(requestMap.isNotEmpty ? requestMap : map);
      final list = (map['responses'] ??
              map['responders'] ??
              requestMap['responses'] ??
              requestMap['responders']) as List? ??
          [];
      responders = list
          .map((e) => Responder.fromJson(asMap(e)))
          .toList();

      // Ensure unitsAccepted and status on request reflect accepted responders
      final acceptedCount = responders.where((r) => r.accepted).length;
      if (request != null) {
        final effectiveUnitsAccepted = request!.unitsAccepted > acceptedCount
            ? request!.unitsAccepted
            : acceptedCount;
        final effectiveStatus = (effectiveUnitsAccepted >= request!.units &&
                request!.status == 'open')
            ? 'matched'
            : request!.status;
        if (effectiveUnitsAccepted != request!.unitsAccepted ||
            effectiveStatus != request!.status) {
          request = request!.copyWith(
            unitsAccepted: effectiveUnitsAccepted,
            status: effectiveStatus,
          );
        }
      }

      limited = false;
      error = null;

      // Also load available donors filtered by radius
      await loadAvailableDonors(id);
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

  Future<void> loadAvailableDonors(String id) async {
    try {
      loadingAvailableDonors = true;
      notifyListeners();

      final data = await ApiClient.instance
          .get('/requests/$id/potential-donors?limit=50');
      final list = extractList(data, ['potentialDonors', 'donors']);
      final allDonors =
          list.map((e) => PotentialDonor.fromJson(asMap(e))).toList();

      final r = request;
      if (r != null) {
        // Location radius rule based on urgency:
        // 1. Normal: within 20 km
        // 2. Urgent: within 10 km
        // 3. Critical: within 5 km
        final radius = maxRadiusKmForUrgency(r.urgency);
        maxRadiusKm = radius;

        double? reqLat = r.lat;
        double? reqLng = r.lng;
        if ((reqLat == null || reqLng == null) && r.city.trim().isNotEmpty) {
          final c = getCoordinatesForCity(r.city.trim());
          if (c != null) {
            reqLat ??= c.$1;
            reqLng ??= c.$2;
          }
        }

        final filtered = <PotentialDonor>[];
        for (final donor in allDonors) {
          double? donorLat = donor.lat;
          double? donorLng = donor.lng;
          if ((donorLat == null || donorLng == null) &&
              donor.city.trim().isNotEmpty) {
            final c = getCoordinatesForCity(donor.city.trim());
            if (c != null) {
              donorLat ??= c.$1;
              donorLng ??= c.$2;
            }
          }

          double? dist = donor.distanceKm;
          if (dist == null &&
              reqLat != null &&
              reqLng != null &&
              donorLat != null &&
              donorLng != null) {
            dist = calculateDistanceKm(reqLat, reqLng, donorLat, donorLng);
          }

          if (dist == null &&
              r.city.trim().isNotEmpty &&
              donor.city.trim().isNotEmpty &&
              r.city.trim().toLowerCase() ==
                  donor.city.trim().toLowerCase()) {
            dist = 0.0;
          }

          // Exclude donors outside the urgency radius
          if (dist != null && dist <= radius) {
            filtered.add(donor.copyWith(
              distanceKm: double.parse(dist.toStringAsFixed(1)),
              lat: donorLat,
              lng: donorLng,
            ));
          }
        }

        filtered.sort(
            (a, b) => (a.distanceKm ?? 9999).compareTo(b.distanceKm ?? 9999));
        availableDonors = filtered;
      } else {
        availableDonors = allDonors;
      }
    } catch (_) {
      // Keep existing available donors on error
    } finally {
      loadingAvailableDonors = false;
      notifyListeners();
    }
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
      limited = false;
      error = null;
      responders = [];
      await loadAvailableDonors(id);
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    }
  }

  Future<String?> cancelRequest(String id) async {
    try {
      await ApiClient.instance.patch('/requests/$id/cancel');
      await load(id, silent: true);
      return null;
    } on ApiException catch (e) {
      // Try admin status route fallback if admin
      try {
        await ApiClient.instance
            .patch('/admin/requests/$id/status', {'status': 'cancelled'});
        await load(id, silent: true);
        return null;
      } on ApiException {
        return e.message;
      } catch (_) {
        return e.message;
      }
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> setStatus(String id, String status) async {
    // Optimistically update request status in memory
    if (request != null && request!.id == id) {
      request = request!.copyWith(status: status);
      notifyListeners();
    }
    try {
      await ApiClient.instance
          .patch('/admin/requests/$id/status', {'status': status});
      await load(id, silent: true);
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.statusCode == 404) {
        try {
          await ApiClient.instance.patch('/requests/$id/fulfill');
          await load(id, silent: true);
          return null;
        } catch (_) {}
        return null;
      }
      return e.message;
    } catch (_) {
      return null;
    }
  }

  void seed(BloodRequest initial) {
    if (request == null || request!.id != initial.id) {
      request = initial;
      responders = [];
      availableDonors = [];
      error = null;
      notifyListeners();
    }
  }

  void clear() {
    request = null;
    responders = [];
    availableDonors = [];
    loading = false;
    loadingAvailableDonors = false;
    error = null;
    limited = false;
    maxRadiusKm = null;
    notifyListeners();
  }
}