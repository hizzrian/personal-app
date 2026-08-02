/// Helpers for reading loosely-typed SQLite / JSON rows into typed fields.
///
/// sqflite returns `Map<String, Object?>`, so every field read is a potential
/// `TypeError` or `FormatException`. These helpers fail with a message that
/// names the offending column instead of throwing deep inside a build method.
class DbRead {
  const DbRead._();

  static String string(Map<String, Object?> map, String key,
      {String fallback = ''}) {
    final value = map[key];
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static int integer(Map<String, Object?> map, String key, {int fallback = 0}) {
    final value = map[key];
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static bool boolean(Map<String, Object?> map, String key,
      {bool fallback = false}) {
    final value = map[key];
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return fallback;
  }

  /// Parses an ISO-8601 string. Falls back to [fallback] (or now) rather than
  /// throwing, so one corrupt row cannot take down an entire list screen.
  static DateTime dateTime(Map<String, Object?> map, String key,
      {DateTime? fallback}) {
    final value = map[key];
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return fallback ?? DateTime.now();
  }

  static List<String> csv(Map<String, Object?> map, String key) {
    final raw = string(map, key);
    if (raw.isEmpty) return const [];
    return raw.split(',').where((e) => e.isNotEmpty).toList();
  }
}
