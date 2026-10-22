import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/format.dart';
import '../models/alert_item.dart';
import '../models/blood_request.dart';
import '../services/api_client.dart';

class AlertProvider extends ChangeNotifier {
  List<AlertItem> alerts = [];
  bool loading = false;
  String? error;

  int get criticalCount => alerts.where((a) => a.isCritical).length;

  Future<void> load({
    bool silent = false,
    String? city,
    String? bloodGroup,
  }) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }

    final Map<String, AlertItem> combined = {};

    // 1. Try GET /alerts
    try {
      final data = await ApiClient.instance.get('/alerts');
      final list = (data is Map ? data['alerts'] : data) as List? ?? [];
      for (final raw in list) {
        final item = AlertItem.fromJson(asMap(raw));
        if (item.requestId.isNotEmpty) {
          combined[item.requestId] = item;
        }
      }
    } catch (_) {}

    // 2. Load open requests from backend (GET /requests)
    try {
      final reqData = await ApiClient.instance.get('/requests?limit=50');
      final rawList =
          extractList(asMap(reqData), ['bloodRequests', 'requests', 'data']);
      for (final raw in rawList) {
        final req = BloodRequest.fromJson(asMap(raw));
        if (req.id.isNotEmpty && req.isOpen) {
          bool isCompatible = true;
          if (bloodGroup != null && bloodGroup.trim().isNotEmpty) {
            final allowed = kDonatesTo[bloodGroup.trim()] ?? [];
            if (allowed.isNotEmpty && !allowed.contains(req.bloodGroup)) {
              isCompatible = false;
            }
          }

          if (isCompatible) {
            combined[req.id] = AlertItem(
              requestId: req.id,
              bloodGroup: req.bloodGroup,
              units: req.units,
              hospitalName: req.hospitalName,
              city: req.city,
              urgency: req.urgency,
              status: req.status,
              lat: req.lat,
              lng: req.lng,
              createdAt: req.createdAt,
              department: (req.patient?['healthIssue'] != null &&
                      req.patient!['healthIssue'].toString().trim().isNotEmpty)
                  ? req.patient!['healthIssue'].toString().trim()
                  : (req.urgency == 3
                      ? 'Emergency Blood Request'
                      : 'Blood Request'),
              donorsPinged: 0,
              routeSnippet: '',
              requesterName: req.requesterName,
              requesterPhone: req.requesterPhone,
            );
          }
        }
      }
    } catch (_) {}

    // 3. Load notifications from backend (GET /notifications)
    try {
      final notifData =
          await ApiClient.instance.get('/notifications?limit=30');
      final notifList =
          extractList(asMap(notifData), ['notifications', 'data']);
      for (final raw in notifList) {
        final m = asMap(raw);
        final item = _fromNotification(
          m,
          fallbackCity: city,
          fallbackBloodGroup: bloodGroup,
        );
        if (item != null && !combined.containsKey(item.requestId)) {
          combined[item.requestId] = item;
        }
      }
    } catch (_) {}

    final list = combined.values.toList();

    // Sort: Donor's city first, then by urgency (critical level 3 first), then newest
    list.sort((a, b) {
      if (city != null && city.trim().isNotEmpty) {
        final aCityMatch =
            a.city.trim().toLowerCase() == city.trim().toLowerCase();
        final bCityMatch =
            b.city.trim().toLowerCase() == city.trim().toLowerCase();
        if (aCityMatch && !bCityMatch) return -1;
        if (!aCityMatch && bCityMatch) return 1;
      }
      if (b.urgency != a.urgency) {
        return b.urgency.compareTo(a.urgency);
      }
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    alerts = list;
    error = null;
    loading = false;
    notifyListeners();
  }

  static AlertItem? _fromNotification(
    Map<String, dynamic> m, {
    String? fallbackCity,
    String? fallbackBloodGroup,
  }) {
    final rel = m['relatedRequest'];
    final relId = (rel is Map ? (rel['_id'] ?? rel['id']) : rel)?.toString();
    if (relId == null || relId.isEmpty) return null;

    final title = (m['title'] ?? '').toString();
    final msg = (m['message'] ?? '').toString();
    final isEmergency = (m['type'] ?? '') == 'emergency' ||
        title.toLowerCase().contains('emergency') ||
        msg.toLowerCase().contains('emergency');

    String bg = fallbackBloodGroup ?? 'A+';
    for (final g in kBloodGroups) {
      final reg = RegExp('(^|\\s)${RegExp.escape(g)}(\\s|\$|,)');
      if (reg.hasMatch(msg)) {
        bg = g;
        break;
      }
    }

    int units = 1;
    final unitsMatch = RegExp(r'Units required:\s*(\d+)').firstMatch(msg);
    if (unitsMatch != null) {
      units = int.tryParse(unitsMatch.group(1)!) ?? 1;
    }

    String city = (fallbackCity != null && fallbackCity.isNotEmpty)
        ? fallbackCity
        : '';
    final cityMatch = RegExp(r'in\s+([A-Za-z\s]+?)\.').firstMatch(msg);
    if (cityMatch != null) {
      city = cityMatch.group(1)!.trim();
    }

    final coords = getCoordinatesForCity(city);

    return AlertItem(
      requestId: relId,
      bloodGroup: bg,
      units: units,
      hospitalName: city.isNotEmpty
          ? 'Hospital in $city'
          : (title.isNotEmpty ? title : 'Emergency Blood Request'),
      city: city.isNotEmpty ? city : 'Local Medical Center',
      urgency: isEmergency ? 3 : 2,
      status: 'open',
      lat: coords?.$1,
      lng: coords?.$2,
      department: isEmergency
          ? 'Emergency Blood Request'
          : (title.isNotEmpty ? title : 'Blood Request'),
      donorsPinged: 0,
      routeSnippet: '',
      createdAt:
          DateTime.tryParse((m['createdAt'] ?? '').toString())?.toLocal(),
    );
  }


  Future<String?> respond(String requestId, bool accept,
      {String? message}) async {
    try {
      await ApiClient.instance.post('/responses/$requestId', {
        'status': accept ? 'accepted' : 'declined',
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      });
      alerts = alerts.where((a) => a.requestId != requestId).toList();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 409 || e.statusCode == 404) {
        alerts = alerts.where((a) => a.requestId != requestId).toList();
        notifyListeners();
      }
      return e.message;
    } catch (_) {
      alerts = alerts.where((a) => a.requestId != requestId).toList();
      notifyListeners();
      return null;
    }
  }

  void clear() {
    alerts = [];
    error = null;
    loading = false;
    notifyListeners();
  }
}