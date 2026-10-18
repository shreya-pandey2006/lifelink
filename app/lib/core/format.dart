String timeAgo(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
int asInt(dynamic v, int fallback) =>
    v is num ? v.toInt() : (int.tryParse('$v') ?? fallback);
double? asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

Map<String, dynamic> asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}

Map<String, dynamic> extractMap(dynamic data, List<String> candidateKeys) {
  final root = asMap(data);
  for (final key in candidateKeys) {
    if (root[key] is Map) return asMap(root[key]);
  }
  if (root['data'] is Map) {
    final nested = asMap(root['data']);
    for (final key in candidateKeys) {
      if (nested[key] is Map) return asMap(nested[key]);
    }
  }
  return root;
}

List<dynamic> extractList(dynamic data, List<String> candidateKeys) {
  if (data is List) return data;
  final root = asMap(data);
  for (final key in candidateKeys) {
    if (root[key] is List) return root[key] as List<dynamic>;
  }
  if (root['data'] is Map) {
    final nested = asMap(root['data']);
    for (final key in candidateKeys) {
      if (nested[key] is List) return nested[key] as List<dynamic>;
    }
  }
  return const [];
}
