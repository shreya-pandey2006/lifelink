class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? requestId;
  final bool read;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.requestId,
    required this.read,
    this.createdAt,
    this.updatedAt,
  });

  bool get isRead => read;

  AppNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    String? requestId,
    bool? read,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AppNotification(
        id: id ?? this.id,
        type: type ?? this.type,
        title: title ?? this.title,
        message: message ?? this.message,
        requestId: requestId ?? this.requestId,
        read: read ?? this.read,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    String? reqId;
    final rel = j['relatedRequest'];
    if (rel is Map) {
      reqId = (rel['_id'] ?? rel['id'])?.toString();
    } else if (rel != null) {
      reqId = rel.toString();
    } else if (j['requestId'] != null) {
      reqId = j['requestId'].toString();
    }

    return AppNotification(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      type: (j['type'] ?? 'general').toString(),
      title: (j['title'] ?? '').toString(),
      message: (j['message'] ?? '').toString(),
      requestId: reqId,
      read: j['isRead'] == true || j['read'] == true,
      createdAt:
          DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal(),
      updatedAt:
          DateTime.tryParse((j['updatedAt'] ?? '').toString())?.toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'type': type,
        'title': title,
        'message': message,
        if (requestId != null) 'relatedRequest': requestId,
        'isRead': read,
        if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
      };
}