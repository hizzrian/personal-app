/// Human-readable relative timestamps.
///
/// Extracted from two byte-identical private copies in the notes and dashboard
/// screens. Pure and static, so it is directly unit-testable.
class RelativeTime {
  const RelativeTime._();

  /// Compact form for list rows: `now`, `5m`, `3h`, `2d`, then `d/M`.
  static String short(DateTime timestamp, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(timestamp);

    if (diff.isNegative) return 'now';
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${timestamp.day}/${timestamp.month}';
  }

  /// Verbose form for detail views: `just now`, `5 minutes ago`, …
  static String long(DateTime timestamp, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(timestamp);

    if (diff.isNegative || diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
}
