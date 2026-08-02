import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/core/failure.dart';
import 'package:personal_app/data/app_database.dart';
import 'package:personal_app/data/backup_repository.dart';
import 'package:personal_app/data/job_repository.dart';
import 'package:personal_app/data/note_repository.dart';
import 'package:personal_app/data/qr_repository.dart';
import 'package:personal_app/models/job_status.dart';
import 'package:personal_app/services/import_service.dart';

import '../support/test_database.dart';

void main() {
  setUpAll(initSqfliteForTests);

  late AppDatabase db;
  late NoteRepository notes;
  late JobRepository jobs;
  late ImportService service;

  setUp(() {
    db = newTestDatabase();
    notes = SqliteNoteRepository(db);
    jobs = SqliteJobRepository(db);
    final qr = SqliteQrRepository(db);
    service = ImportService(SqliteBackupRepository(db, notes, jobs, qr));
  });

  tearDown(() => db.close());

  String payload(Map<String, Object?> data) => jsonEncode({'data': data});

  group('rejects bad input', () {
    test('non-JSON text', () async {
      final result = await service.importFromJson('not json at all');
      expect(result.failureOrNull, isA<ParseFailure>());
    });

    test('a JSON array at the top level', () async {
      final result = await service.importFromJson('[1,2,3]');
      expect(result.failureOrNull, isA<ParseFailure>());
    });

    test('a payload with no "data" key', () async {
      final result = await service.importFromJson('{"other":1}');
      expect(result.failureOrNull, isA<ParseFailure>());
      expect(result.failureOrNull?.message, contains('data'));
    });

    test('a payload with no recognisable records', () async {
      final result = await service.importFromJson(payload({'notes': []}));
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('records missing an id', () async {
      final result = await service.importFromJson(payload({
        'notes': [
          {'title': 'no id here'},
        ],
      }));
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('coerces untrusted field types', () {
    test('accepts a real boolean for isPinned', () async {
      // The old implementation passed `true` straight to an INTEGER column,
      // which threw and surfaced as a misleading "failed to parse JSON".
      final result = await service.importFromJson(payload({
        'notes': [
          {
            'id': 'n1',
            'title': 'Pinned',
            'body': 'b',
            'isPinned': true,
            'createdAt': '2026-01-01T00:00:00.000',
            'updatedAt': '2026-01-01T00:00:00.000',
          },
        ],
      }));

      expect(result.isOk, isTrue);
      final saved = (await notes.all()).valueOr(const []).single;
      expect(saved.isPinned, isTrue);
    });

    test('accepts a numeric string for color', () async {
      final result = await service.importFromJson(payload({
        'notes': [
          {
            'id': 'n1',
            'title': 't',
            'body': 'b',
            'color': '42',
            'createdAt': '2026-01-01T00:00:00.000',
            'updatedAt': '2026-01-01T00:00:00.000',
          },
        ],
      }));

      expect(result.isOk, isTrue);
      expect((await notes.all()).valueOr(const []).single.color, 42);
    });

    test('substitutes a valid date for an unparseable one', () async {
      final result = await service.importFromJson(payload({
        'notes': [
          {
            'id': 'n1',
            'title': 't',
            'body': 'b',
            'createdAt': 'definitely-not-a-date',
            'updatedAt': 'also-not-a-date',
          },
        ],
      }));

      expect(result.isOk, isTrue);
      // Reading it back must not throw, which was the old failure mode.
      expect((await notes.all()).valueOr(const []).single.id, 'n1');
    });

    test('coerces a non-string title rather than failing', () async {
      final result = await service.importFromJson(payload({
        'notes': [
          {
            'id': 'n1',
            'title': 12345,
            'body': 'b',
            'createdAt': '2026-01-01T00:00:00.000',
            'updatedAt': '2026-01-01T00:00:00.000',
          },
        ],
      }));

      expect(result.isOk, isTrue);
      expect((await notes.all()).valueOr(const []).single.title, '12345');
    });

    test('falls back to "applied" for an unknown job status', () async {
      final result = await service.importFromJson(payload({
        'jobs': [
          {
            'id': 'j1',
            'company': 'Acme',
            'position': 'Dev',
            'status': 'totally-made-up',
            'appliedDate': '2026-01-01T00:00:00.000',
            'updatedAt': '2026-01-01T00:00:00.000',
          },
        ],
      }));

      expect(result.isOk, isTrue);
      expect(
        (await jobs.all()).valueOr(const []).single.status,
        JobStatus.applied,
      );
    });

    test('ignores non-map entries inside a table array', () async {
      final result = await service.importFromJson(payload({
        'notes': [
          'a bare string',
          42,
          {
            'id': 'n1',
            'title': 't',
            'body': 'b',
            'createdAt': '2026-01-01T00:00:00.000',
            'updatedAt': '2026-01-01T00:00:00.000',
          },
        ],
      }));

      expect(result.isOk, isTrue);
      expect((await notes.count()).valueOr(0), 1);
    });
  });

  test('reports accurate counts across tables', () async {
    final result = await service.importFromJson(payload({
      'notes': [
        {
          'id': 'n1',
          'title': 't',
          'body': 'b',
          'createdAt': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-01T00:00:00.000',
        },
      ],
      'jobs': [
        {
          'id': 'j1',
          'company': 'Acme',
          'position': 'Dev',
          'appliedDate': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-01T00:00:00.000',
        },
      ],
    }));

    final counts = result.valueOrNull;
    expect(counts?.notes, 1);
    expect(counts?.jobs, 1);
    expect(counts?.total, 2);
  });

  test('re-importing the same payload adds nothing', () async {
    final json = payload({
      'notes': [
        {
          'id': 'n1',
          'title': 't',
          'body': 'b',
          'createdAt': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-01T00:00:00.000',
        },
      ],
    });

    expect((await service.importFromJson(json)).valueOrNull?.total, 1);
    expect((await service.importFromJson(json)).valueOrNull?.total, 0);
    expect((await notes.count()).valueOr(0), 1);
  });

  group('note previews', () {
    Future<String?> importedPreview(Map<String, Object?> noteRow) async {
      final result = await service.importFromJson(payload({
        'notes': [noteRow],
      }));
      expect(result.valueOrNull?.total, 1);
      final rows =
          await (await db.open()).query('notes', columns: ['previewText']);
      return rows.single['previewText'] as String?;
    }

    test('derives the preview from an imported body', () async {
      final body = jsonEncode([
        {'insert': 'imported line\n'},
      ]);
      expect(
        await importedPreview({
          'id': 'n1',
          'title': 't',
          'body': body,
          'createdAt': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-01T00:00:00.000',
        }),
        'imported line',
      );
    });

    test('ignores a preview supplied by the file', () async {
      // A hand-edited backup could claim a preview that contradicts its body.
      // Trusting it would show the list text the note does not contain.
      expect(
        await importedPreview({
          'id': 'n1',
          'title': 't',
          'body': 'real body',
          'previewText': 'attacker supplied',
          'createdAt': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-01T00:00:00.000',
        }),
        'real body',
      );
    });
  });
}
