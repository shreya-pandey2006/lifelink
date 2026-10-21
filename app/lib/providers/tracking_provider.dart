import 'package:flutter/material.dart';
import '../models/blood_request.dart';
import '../models/responder.dart';
import '../services/api_client.dart';
import '../core/format.dart';

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
      limited = false;
      error = null;
      responders = [];
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

  void seed(BloodRequest initial) {
    if (request == null || request!.id != initial.id) {
      request = initial;
      responders = [];
      error = null;
      notifyListeners();
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