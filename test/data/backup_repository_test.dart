import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/core/result.dart';
import 'package:personal_app/data/app_database.dart';
import 'package:personal_app/data/backup_repository.dart';
import 'package:personal_app/data/job_repository.dart';
import 'package:personal_app/data/note_repository.dart';
import 'package:personal_app/data/qr_repository.dart';
import 'package:personal_app/models/job.dart';
import 'package:personal_app/models/note.dart';
import 'package:personal_app/models/qr_item.dart';

import '../support/test_database.dart';

void main() {
  setUpAll(initSqfliteForTests);

  late AppDatabase db;
  late NoteRepository notes;
  late JobRepository jobs;
  late QrRepository qr;
  late BackupRepository backup;

  setUp(() {
    db = newTestDatabase();
    notes = SqliteNoteRepository(db);
    jobs = SqliteJobRepository(db);
    qr = SqliteQrRepository(db);
    backup = SqliteBackupRepository(db, notes, jobs, qr);
  });

  tearDown(() => db.close());

  T unwrap<T>(Result<T> result) => result.fold(
        onOk: (value) => value,
        onErr: (failure) => fail('expected Ok but got: ${failure.message}'),
      );

  Future<void> seed() async {
    unwrap(await notes.save(Note(
      id: 'n1',
      title: 'Note one',
      body: 'body',
      tags: const ['a'],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    )));
    unwrap(await jobs.save(Job(
      id: 'j1',
      company: 'Acme',
      position: 'Engineer',
      appliedDate: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    )));
    unwrap(await qr.save(QrItem(
      id: 'q1',
      label: 'WiFi',
      data: 'WIFI:S:x;;',
      createdAt: DateTime(2026, 1, 1),
    )));
  }

  group('exportAll', () {
    test('returns every table', () async {
      await seed();
      final data = unwrap(await backup.exportAll());

      expect(data[AppDatabase.tableNotes], hasLength(1));
      expect(data[AppDatabase.tableJobs], hasLength(1));
      expect(data[AppDatabase.tableQrCodes], hasLength(1));
    });

    test('returns empty lists when there is no data', () async {
      final data = unwrap(await backup.exportAll());
      expect(data[AppDatabase.tableNotes], isEmpty);
      expect(data[AppDatabase.tableJobs], isEmpty);
      expect(data[AppDatabase.tableQrCodes], isEmpty);
    });
  });

  group('clearAll', () {
    test('empties all three tables', () async {
      await seed();
      unwrap(await backup.clearAll());

      expect(unwrap(await notes.count()), 0);
      expect(unwrap(await jobs.count()), 0);
      expect(unwrap(await qr.count()), 0);
    });

    test('leaves the database usable afterwards', () async {
      await seed();
      unwrap(await backup.clearAll());

      unwrap(await notes.save(Note(
        id: 'after',
        title: 'After clear',
        body: '',
        createdAt: DateTime(2026, 2, 2),
        updatedAt: DateTime(2026, 2, 2),
      )));
      expect(unwrap(await notes.count()), 1);
    });
  });

  group('importAll', () {
    Map<String, Object?> noteRow(String id) => {
          'id': id,
          'title': 'Imported $id',
          'body': 'body',
          'tags': '',
          'color': 0,
          'isPinned': 0,
          'createdAt': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-01T00:00:00.000',
        };

    test('inserts new rows and reports the counts', () async {
      final counts = unwrap(await backup.importAll(
        notes: [noteRow('a'), noteRow('b')],
        jobs: const [],
        qrCodes: const [],
      ));

      expect(counts.notes, 2);
      expect(counts.jobs, 0);
      expect(counts.total, 2);
      expect(unwrap(await notes.count()), 2);
    });

    test('skips ids that already exist rather than duplicating', () async {
      await seed(); // creates note n1

      final counts = unwrap(await backup.importAll(
        notes: [noteRow('n1'), noteRow('brand-new')],
        jobs: const [],
        qrCodes: const [],
      ));

      // Only the new one counts.
      expect(counts.notes, 1);
      expect(unwrap(await notes.count()), 2);
    });

    test('does not overwrite an existing row when the id collides', () async {
      await seed();
      unwrap(await backup.importAll(
        notes: [noteRow('n1')],
        jobs: const [],
        qrCodes: const [],
      ));

      final existing = unwrap(await notes.all()).firstWhere((n) => n.id == 'n1');
      // The original title survives; INSERT OR IGNORE must not clobber it.
      expect(existing.title, 'Note one');
    });

    test('reports zero when every row is a duplicate', () async {
      await seed();
      final counts = unwrap(await backup.importAll(
        notes: [noteRow('n1')],
        jobs: const [],
        qrCodes: const [],
      ));
      expect(counts.total, 0);
    });

    test('imports all three entity types together', () async {
      final counts = unwrap(await backup.importAll(
        notes: [noteRow('n9')],
        jobs: [
          {
            'id': 'j9',
            'company': 'Globex',
            'position': 'Dev',
            'location': '',
            'salary': '',
            'status': 'applied',
            'notes': '',
            'appliedDate': '2026-01-01T00:00:00.000',
            'updatedAt': '2026-01-01T00:00:00.000',
          }
        ],
        qrCodes: [
          {
            'id': 'q9',
            'label': 'L',
            'data': 'D',
            'createdAt': '2026-01-01T00:00:00.000',
          }
        ],
      ));

      expect(counts.notes, 1);
      expect(counts.jobs, 1);
      expect(counts.qrCodes, 1);
      expect(counts.total, 3);
    });

    test('skips a malformed row but still commits the valid ones', () async {
      // INSERT OR IGNORE suppresses every constraint violation, not just
      // primary-key conflicts, so a row missing NOT NULL columns is dropped
      // rather than aborting the transaction. The reported count reflects only
      // what actually landed, so the number shown to the user stays truthful.
      //
      // In practice ImportService fills in defaults for every column before
      // reaching here, so this is a defence-in-depth path.
      final counts = unwrap(await backup.importAll(
        notes: [
          noteRow('good'),
          {'id': 'bad'}, // missing NOT NULL title/body/createdAt/updatedAt
        ],
        jobs: const [],
        qrCodes: const [],
      ));

      expect(counts.notes, 1, reason: 'only the valid row is counted');
      expect(unwrap(await notes.count()), 1);
      expect(unwrap(await notes.all()).single.id, 'good');
    });

    test('a genuine transaction failure leaves no partial import', () async {
      // Drop the jobs table so the jobs phase throws after notes have already
      // been inserted inside the same transaction.
      final raw = await db.open();
      await raw.execute('DROP TABLE ${AppDatabase.tableJobs}');

      final result = await backup.importAll(
        notes: [noteRow('n-rollback')],
        jobs: [
          {'id': 'j1', 'company': 'X', 'position': 'Y'},
        ],
        qrCodes: const [],
      );

      expect(result.isErr, isTrue);
      expect(unwrap(await notes.count()), 0,
          reason: 'the note inserted before the failure must be rolled back');
    });

    test('handles an empty import', () async {
      final counts = unwrap(await backup.importAll(
        notes: const [],
        jobs: const [],
        qrCodes: const [],
      ));
      expect(counts.total, 0);
    });
  });
}
