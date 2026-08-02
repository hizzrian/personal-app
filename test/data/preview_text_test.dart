import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:personal_app/core/result.dart';
import 'package:personal_app/data/app_database.dart';
import 'package:personal_app/data/note_repository.dart';
import 'package:personal_app/models/note.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/test_database.dart';

/// Covers the v4 denormalisation: note previews are computed on write and read
/// straight out of their own column, so drawing a list never decodes a Delta.
void main() {
  setUpAll(initSqfliteForTests);

  /// A minimal Quill Delta. Quill rejects a document whose final insert has no
  /// trailing newline, so one is appended when missing.
  String delta(String text) => jsonEncode([
        {'insert': text.endsWith('\n') ? text : '$text\n'},
      ]);

  T unwrap<T>(Result<T> result) => result.fold(
        onOk: (value) => value,
        onErr: (failure) => fail('expected Ok but got: ${failure.message}'),
      );

  Note noteWith({required String id, required String body}) => Note(
        id: id,
        title: 'Title',
        body: body,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  group('Note.previewText', () {
    test('is derived from the body when no stored value is given', () {
      final note = noteWith(id: 'a', body: delta('line one\nline two'));
      expect(note.previewText, 'line one line two');
    });

    test('uses the stored value instead of re-deriving', () {
      // A caller handing over a stored preview must be believed, otherwise the
      // read path would decode the Delta anyway and the column buys nothing.
      final note = Note(
        id: 'a',
        title: 'Title',
        body: delta('body text'),
        previewText: 'stored preview',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(note.previewText, 'stored preview');
    });

    test('falls back to deriving when the column is empty', () {
      // Rows written before v4 have an empty column; they must still show text.
      final note = Note.fromMap({
        'id': 'a',
        'title': 'Title',
        'body': delta('recovered'),
        'previewText': '',
        'tags': '',
        'color': 0,
        'isPinned': 0,
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      });
      expect(note.previewText, 'recovered');
    });

    test('handles legacy plain-text bodies', () {
      expect(noteWith(id: 'a', body: 'old note').previewText, 'old note');
    });

    test('copyWith re-derives when the body changes', () {
      final original = noteWith(id: 'a', body: delta('before'));
      final edited = original.copyWith(body: delta('after'));
      expect(edited.previewText, 'after');
    });

    test('copyWith keeps the preview when the body is untouched', () {
      final original = noteWith(id: 'a', body: delta('unchanged'));
      final renamed = original.copyWith(title: 'New title');
      expect(renamed.previewText, 'unchanged');
    });
  });

  group('SqliteNoteRepository', () {
    late AppDatabase db;
    late NoteRepository repo;

    setUp(() {
      db = newTestDatabase();
      repo = SqliteNoteRepository(db);
    });

    tearDown(() => db.close());

    test('save stores the preview alongside the body', () async {
      unwrap(await repo.save(noteWith(id: 'a', body: delta('stored line'))));

      final raw =
          await (await db.open()).query('notes', columns: ['previewText']);
      expect(raw.single['previewText'], 'stored line');
    });

    test('all() returns the stored preview', () async {
      unwrap(await repo.save(noteWith(id: 'a', body: delta('from column'))));

      final loaded = unwrap(await repo.all());
      expect(loaded.single.previewText, 'from column');
    });

    test('re-saving an edited body refreshes the stored preview', () async {
      final original = noteWith(id: 'a', body: delta('first'));
      unwrap(await repo.save(original));
      unwrap(await repo.save(original.copyWith(body: delta('second'))));

      final loaded = unwrap(await repo.all());
      expect(loaded.single.previewText, 'second');
    });
  });

  group('migration to v4', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('clarity_preview_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    /// Creates a v3 database — the schema right before previewText existed —
    /// seeded with [bodies] keyed by note id.
    Future<String> seedV3(Map<String, String> bodies) async {
      final path = p.join(tempDir.path, 'test.db');
      final v3 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, _) async {
            await db.execute('''
              CREATE TABLE notes (
                id TEXT PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL,
                tags TEXT NOT NULL DEFAULT '', color INTEGER NOT NULL DEFAULT 0,
                isPinned INTEGER NOT NULL DEFAULT 0,
                createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL)
            ''');
            await db.execute('''
              CREATE TABLE jobs (
                id TEXT PRIMARY KEY, company TEXT NOT NULL, position TEXT NOT NULL,
                location TEXT NOT NULL DEFAULT '', salary TEXT NOT NULL DEFAULT '',
                status TEXT NOT NULL DEFAULT 'applied', notes TEXT NOT NULL DEFAULT '',
                appliedDate TEXT NOT NULL, updatedAt TEXT NOT NULL)
            ''');
            await db.execute('''
              CREATE TABLE qr_codes (
                id TEXT PRIMARY KEY, label TEXT NOT NULL,
                data TEXT NOT NULL, createdAt TEXT NOT NULL)
            ''');
          },
        ),
      );

      for (final entry in bodies.entries) {
        await v3.insert('notes', {
          'id': entry.key,
          'title': 'Title ${entry.key}',
          'body': entry.value,
          'tags': '',
          'color': 0,
          'isPinned': 0,
          'createdAt': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-01T00:00:00.000',
        });
      }
      await v3.close();
      return path;
    }

    test('backfills previews for notes written before the column existed',
        () async {
      final path = await seedV3({
        'rich': delta('a rich note\nsecond line'),
        'legacy': 'a plain note',
        'blank': '',
      });

      final appDb = AppDatabase(factory: databaseFactoryFfi, path: path);
      addTearDown(appDb.close);
      final upgraded = await appDb.open();

      final rows =
          await upgraded.query('notes', columns: ['id', 'previewText']);
      final previews = {
        for (final row in rows) row['id']: row['previewText'],
      };

      expect(previews['rich'], 'a rich note second line');
      expect(previews['legacy'], 'a plain note');
      expect(previews['blank'], '');
    });

    test('leaves the rest of each row untouched', () async {
      final path = await seedV3({'rich': delta('body survives')});

      final appDb = AppDatabase(factory: databaseFactoryFfi, path: path);
      addTearDown(appDb.close);
      final upgraded = await appDb.open();

      final row = (await upgraded.query('notes')).single;
      expect(row['title'], 'Title rich');
      expect(row['body'], delta('body survives'));
      expect(row['createdAt'], '2026-01-01T00:00:00.000');
    });

    test('an empty notes table upgrades without error', () async {
      final path = await seedV3(const {});

      final appDb = AppDatabase(factory: databaseFactoryFfi, path: path);
      addTearDown(appDb.close);
      final upgraded = await appDb.open();

      expect(await upgraded.query('notes'), isEmpty);
    });
  });
}
