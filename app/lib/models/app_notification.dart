class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? requestId;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.requestId,
    required this.read,
    this.createdAt,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        requestId: requestId,
        read: read ?? this.read,
        createdAt: createdAt,
      );

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        type: (j['type'] ?? 'update').toString(),
        title: (j['title'] ?? '').toString(),
        message: (j['message'] ?? '').toString(),
        requestId: j['requestId']?.toString(),
        read: j['read'] == true,
        createdAt:
            DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal(),
      );
}