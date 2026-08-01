import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/models/job_status.dart';

void main() {
  group('JobStatus.fromDb', () {
    test('reads every stored value back to its own member', () {
      // Round-trips the whole set, so adding a member without a matching
      // dbValue cannot pass unnoticed.
      for (final status in JobStatus.values) {
        expect(JobStatus.fromDb(status.dbValue), status, reason: status.name);
      }
    });

    test('falls back to applied for an unknown value', () {
      expect(JobStatus.fromDb('bogus'), JobStatus.applied);
    });

    test('falls back to applied for null and empty', () {
      expect(JobStatus.fromDb(null), JobStatus.applied);
      expect(JobStatus.fromDb(''), JobStatus.applied);
    });

    test('is case sensitive, matching how the column is written', () {
      expect(JobStatus.fromDb('Interview'), JobStatus.applied);
    });
  });

  group('stored form', () {
    test('matches the strings written before the enum existed', () {
      // These are the literals the v1 schema wrote. Changing any of them would
      // silently reset a user's applications to "Applied" on next launch.
      expect(JobStatus.values.map((s) => s.dbValue).toList(), [
        'applied',
        'screening',
        'interview',
        'technical',
        'offer',
        'accepted',
        'rejected',
        'withdrawn',
      ]);
    });
  });

  group('classification', () {
    test('terminal statuses are the resolved ones', () {
      expect(
        JobStatus.values.where((s) => s.isTerminal).toSet(),
        {JobStatus.rejected, JobStatus.withdrawn, JobStatus.accepted},
      );
    });

    test('offer covers both offered and accepted', () {
      expect(
        JobStatus.values.where((s) => s.isOffer).toSet(),
        {JobStatus.offer, JobStatus.accepted},
      );
    });
  });

  group('presentation', () {
    test('every status carries a label and a colour', () {
      for (final status in JobStatus.values) {
        expect(status.label, isNotEmpty, reason: status.name);
        expect(status.colorValue, isNot(0), reason: status.name);
      }
    });

    test('colours are distinct, so two stages never look alike', () {
      final colors = JobStatus.values.map((s) => s.colorValue).toSet();
      expect(colors, hasLength(JobStatus.values.length));
    });
  });
}
