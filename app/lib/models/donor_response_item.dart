class DonorResponseItem {
  final String id;
  final String requestId;
  final String bloodGroup;
  final String city;
  final int units;
  final String urgency;
  final String requestStatus;
  final String status; // 'accepted' | 'declined'
  final String message;
  final DateTime? createdAt;

  const DonorResponseItem({
    required this.id,
    required this.requestId,
    required this.bloodGroup,
    required this.city,
    required this.units,
    required this.urgency,
    required this.requestStatus,
    required this.status,
    this.message = '',
    this.createdAt,
  });

  bool get isAccepted => status == 'accepted';

  factory DonorResponseItem.fromJson(Map<String, dynamic> j) {
    final req = j['bloodRequest'] is Map ? Map<String, dynamic>.from(j['bloodRequest'] as Map) : <String, dynamic>{};
    return DonorResponseItem(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      requestId: (req['_id'] ?? req['id'] ?? j['bloodRequest'] ?? '').toString(),
      bloodGroup: (req['bloodGroup'] ?? '').toString(),
      city: (req['city'] ?? '').toString(),
      units: req['units'] is num ? (req['units'] as num).toInt() : (int.tryParse('${req['units']}') ?? 1),
      urgency: (req['urgency'] ?? 'normal').toString(),
      requestStatus: (req['status'] ?? 'open').toString(),
      status: (j['status'] ?? 'accepted').toString(),
      message: (j['message'] ?? '').toString(),
      createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal(),
    );
  }
}
