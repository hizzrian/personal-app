import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:personal_app/data/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/test_database.dart';

/// Verifies the upgrade path from every historical schema version.
/// Previously untestable, since the schema lived behind a hard-coded singleton.
///
/// These use real temp files, not `inMemoryDatabasePath`: an in-memory database
/// is discarded when its connection closes, so reopening would silently run
/// `onCreate` instead of `onUpgrade` and the test would pass without ever
/// exercising a migration.
void main() {
  setUpAll(initSqfliteForTests);

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('clarity_migration_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  String dbPath() => p.join(tempDir.path, 'test.db');

  Future<Set<String>> tableNames(Database db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    return rows.map((r) => r['name']! as String).toSet();
  }

  Future<Set<String>> indexNames(Database db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'",
    );
    return rows.map((r) => r['name']! as String).toSet();
  }

  test('a fresh install creates every table and index', () async {
    final appDb = AppDatabase(factory: databaseFactoryFfi, path: dbPath());
    addTearDown(appDb.close);

    final db = await appDb.open();

    expect(await tableNames(db), containsAll(['notes', 'jobs', 'qr_codes']));
    expect(
      await indexNames(db),
      containsAll([
        'idx_notes_pinned_updated',
        'idx_jobs_updated',
        'idx_jobs_status',
        'idx_qr_created',
      ]),
    );
  });

  test('upgrading from v1 adds qr_codes and the indexes', () async {
    // Simulate a v1 install: notes + jobs only, no qr_codes, no indexes.
    final path = dbPath();
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
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
        },
      ),
    );

    // Seed a row so we can prove the migration preserves existing data.
    await v1.insert('notes', {
      'id': 'legacy',
      'title': 'Pre-migration note',
      'body': 'body',
      'tags': '',
      'color': 0,
      'isPinned': 0,
      'createdAt': '2026-01-01T00:00:00.000',
      'updatedAt': '2026-01-01T00:00:00.000',
    });
    expect(await tableNames(v1), isNot(contains('qr_codes')));
    await v1.close();

    // Reopen at the current version — this runs _onUpgrade 1 → 3.
    final upgraded = await AppDatabase(
      factory: databaseFactoryFfi,
      path: path,
    ).open();
    addTearDown(upgraded.close);

    expect(await tableNames(upgraded), contains('qr_codes'));
    expect(await indexNames(upgraded), contains('idx_notes_pinned_updated'));

    final preserved = await upgraded.query('notes', where: 'id = ?', whereArgs: ['legacy']);
    expect(preserved, hasLength(1));
    expect(preserved.single['title'], 'Pre-migration note');
  });

  test('upgrading from v2 adds only the indexes', () async {
    final path = dbPath();
    final v2 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
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
    expect(await indexNames(v2), isEmpty);
    await v2.close();

    final upgraded = await AppDatabase(
      factory: databaseFactoryFfi,
      path: path,
    ).open();
    addTearDown(upgraded.close);

    expect(await indexNames(upgraded), hasLength(4));
    expect(await tableNames(upgraded), containsAll(['notes', 'jobs', 'qr_codes']));
  });

  test('reopening at the current version is a no-op', () async {
    final path = dbPath();

    final first = AppDatabase(factory: databaseFactoryFfi, path: path);
    await first.open();
    await first.close();

    // Must not throw on the second open (the migration must be idempotent).
    final second = AppDatabase(factory: databaseFactoryFfi, path: path);
    final db = await second.open();
    addTearDown(second.close);

    expect(await indexNames(db), hasLength(4));
  });
}
