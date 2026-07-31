import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/utils/relative_time.dart';

void main() {
  // Fixed reference so these never depend on the wall clock.
  final now = DateTime(2026, 7, 31, 12, 0);

  group('RelativeTime.short', () {
    test('reports "now" under a minute', () {
      expect(
        RelativeTime.short(now.subtract(const Duration(seconds: 30)), now: now),
        'now',
      );
    });

    test('reports minutes under an hour', () {
      expect(
        RelativeTime.short(now.subtract(const Duration(minutes: 45)), now: now),
        '45m',
      );
    });

    test('reports hours under a day', () {
      expect(
        RelativeTime.short(now.subtract(const Duration(hours: 5)), now: now),
        '5h',
      );
    });

    test('reports days under a week', () {
      expect(
        RelativeTime.short(now.subtract(const Duration(days: 3)), now: now),
        '3d',
      );
    });

    test('falls back to day/month beyond a week', () {
      expect(
        RelativeTime.short(DateTime(2026, 3, 9), now: now),
        '9/3',
      );
    });

    test('treats a future timestamp as "now" rather than going negative', () {
      expect(
        RelativeTime.short(now.add(const Duration(hours: 2)), now: now),
        'now',
      );
    });

    test('boundary: exactly 60 minutes reads as hours', () {
      expect(
        RelativeTime.short(now.subtract(const Duration(minutes: 60)), now: now),
        '1h',
      );
    });

    test('boundary: exactly 7 days falls through to day/month', () {
      expect(
        RelativeTime.short(now.subtract(const Duration(days: 7)), now: now),
        '24/7',
      );
    });
  });

  group('RelativeTime.long', () {
    test('reports "just now" under a minute', () {
      expect(
        RelativeTime.long(now.subtract(const Duration(seconds: 10)), now: now),
        'just now',
      );
    });

    test('singularises one minute', () {
      expect(
        RelativeTime.long(now.subtract(const Duration(minutes: 1)), now: now),
        '1 minute ago',
      );
    });

    test('pluralises multiple minutes', () {
      expect(
        RelativeTime.long(now.subtract(const Duration(minutes: 20)), now: now),
        '20 minutes ago',
      );
    });

    test('singularises one hour', () {
      expect(
        RelativeTime.long(now.subtract(const Duration(hours: 1)), now: now),
        '1 hour ago',
      );
    });

    test('reports days beyond 24 hours', () {
      expect(
        RelativeTime.long(now.subtract(const Duration(days: 2)), now: now),
        '2 days ago',
      );
    });
  });
}
