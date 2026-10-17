import 'api_client.dart';
import '../core/format.dart';

class MlPredictionResult {
  final bool success;
  final String? predictedUrgency;
  final double? confidence;
  final String? rawStatus;

  const MlPredictionResult({
    required this.success,
    this.predictedUrgency,
    this.confidence,
    this.rawStatus,
  });

  factory MlPredictionResult.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString();
    final urgency = json['predicted_urgency_level']?.toString() ??
        json['predictedUrgency']?.toString() ??
        json['urgency']?.toString();
    final conf = asDouble(json['confidence_score'] ?? json['confidence']);
    return MlPredictionResult(
      success: status == 'success' || urgency != null,
      predictedUrgency: urgency,
      confidence: (conf != null && conf > 0) ? conf : null,
      rawStatus: status,
    );
  }
}

class MlRankedDonor {
  final String donorId;
  final double responseProbability;

  const MlRankedDonor({
    required this.donorId,
    required this.responseProbability,
  });

  factory MlRankedDonor.fromJson(Map<String, dynamic> json) {
    return MlRankedDonor(
      donorId: (json['donorId'] ?? json['donor_id'] ?? '').toString(),
      responseProbability:
          asDouble(json['response_probability'] ?? json['probability']) ?? 0.0,
    );
  }
}

class MlService {
  MlService._();
  static final MlService instance = MlService._();

  Future<MlPredictionResult?> predictUrgency({
    required int age,
    required String gender,
    required double weightKg,
    required String bloodGroup,
    required String city,
    required String healthIssue,
    double? hemoglobinGDl,
    int? plateletCount,
    int? systolicBp,
    int? heartRate,
    int? spo2Percent,
    bool activeBleeding = false,
    bool previousTransfusions = false,
    String? bloodComponentNeeded,
    int unitsRequired = 1,
    int? requiredWithinHours,
  }) async {
    try {
      final body = <String, dynamic>{
        'age': age,
        'gender': gender,
        'weight_kg': weightKg,
        'blood_group': bloodGroup,
        'city': city,
        'health_issue': healthIssue,
        'hemoglobin_g_dl': ?hemoglobinGDl,
        'platelet_count': ?plateletCount,
        'systolic_bp': ?systolicBp,
        'heart_rate': ?heartRate,
        'spo2_percent': ?spo2Percent,
        'active_bleeding': activeBleeding,
        'previous_transfusions': previousTransfusions,
        'blood_component_needed': ?bloodComponentNeeded,
        'units_required': unitsRequired,
        'required_within_hours': ?requiredWithinHours,
      };

      final data = await ApiClient.instance.post('/ml/predict-urgency', body);
      if (data is Map) {
        return MlPredictionResult.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<MlRankedDonor>> rankDonors(
      List<Map<String, dynamic>> donors) async {
    try {
      final data =
          await ApiClient.instance.post('/ml/rank-donors', {'donors': donors});
      if (data is Map) {
        final list = (data['ranked_donors'] ?? data['donors']) as List? ?? [];
        return list
            .map((e) =>
                MlRankedDonor.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
