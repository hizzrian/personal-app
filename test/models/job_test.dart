import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/models/job.dart';
import 'package:personal_app/models/job_status.dart';

void main() {
  Job jobWith(JobStatus status) => Job(
        id: 'j1',
        company: 'Acme',
        position: 'Engineer',
        status: status,
        appliedDate: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  group('Job.isActive', () {
    test('is true for in-progress statuses', () {
      for (final status in JobStatus.values.where((s) => !s.isTerminal)) {
        expect(jobWith(status).isActive, isTrue, reason: status.name);
      }
    });

    test('is false for terminal statuses', () {
      for (final status in JobStatus.values.where((s) => s.isTerminal)) {
        expect(jobWith(status).isActive, isFalse, reason: status.name);
      }
    });
  });

  group('Job.isOffer', () {
    test('is true for offer and accepted', () {
      expect(jobWith(JobStatus.offer).isOffer, isTrue);
      expect(jobWith(JobStatus.accepted).isOffer, isTrue);
    });

    test('is false otherwise', () {
      for (final status in JobStatus.values.where((s) => !s.isOffer)) {
        expect(jobWith(status).isOffer, isFalse, reason: status.name);
      }
    });
  });

  group('Job.fromMap', () {
    Map<String, Object?> validRow() => {
          'id': 'j1',
          'company': 'Acme',
          'position': 'Engineer',
          'location': 'Remote',
          'salary': '10M',
          'status': 'interview',
          'notes': 'n',
          'appliedDate': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-02T00:00:00.000',
        };

    test('reads a well-formed row', () {
      final job = Job.fromMap(validRow());
      expect(job.id, 'j1');
      expect(job.status, JobStatus.interview);
      expect(job.appliedDate, DateTime.parse('2026-01-01T00:00:00.000'));
    });

    test('coerces an unknown status to applied', () {
      // A value with no enum member must not reach a screen that would have
      // no label or colour for it.
      final job = Job.fromMap(validRow()..['status'] = 'bogus');
      expect(job.status, JobStatus.applied);
    });

    test('does not throw on a malformed date', () {
      // Previously DateTime.parse threw here and took down the list screen.
      expect(
        () => Job.fromMap(validRow()..['appliedDate'] = 'not-a-date'),
        returnsNormally,
      );
    });

    test('does not throw on null text columns', () {
      final job = Job.fromMap(validRow()..['location'] = null);
      expect(job.location, '');
    });

    test('accepts an integer millisecond timestamp', () {
      final millis = DateTime(2026, 5, 5).millisecondsSinceEpoch;
      final job = Job.fromMap(validRow()..['appliedDate'] = millis);
      expect(job.appliedDate, DateTime(2026, 5, 5));
    });
  });

  test('toMap round-trips through fromMap', () {
    final original = jobWith(JobStatus.offer);
    final restored = Job.fromMap(original.toMap());
    expect(restored.id, original.id);
    expect(restored.status, original.status);
    expect(restored.company, original.company);
    expect(restored.appliedDate, original.appliedDate);
  });
}
