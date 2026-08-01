import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/db_read.dart';
import '../utils/note_body.dart';

/// Owns the SQLite connection and schema. Injected into repositories so tests
/// can supply an in-memory database instead of a real file.
class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? path})
      : _factory = factory,
        _path = path;

  /// Overridable so tests can pass `databaseFactoryFfi`.
  final DatabaseFactory? _factory;

  /// Overridable so tests can pass `inMemoryDatabasePath`.
  final String? _path;

  Database? _db;

  static const schemaVersion = 4;

  static const tableNotes = 'notes';
  static const tableJobs = 'jobs';
  static const tableQrCodes = 'qr_codes';

  Future<Database> open() async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;

    final factory = _factory ?? databaseFactory;
    final path = _path ?? p.join(await factory.getDatabasesPath(), 'personal_app.db');

    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    _db = db;
    return db;
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null && db.isOpen) await db.close();
  }

  // --- Schema ---------------------------------------------------------------

  static const _createNotes = '''
    CREATE TABLE IF NOT EXISTS $tableNotes (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      previewText TEXT NOT NULL DEFAULT '',
      tags TEXT NOT NULL DEFAULT '',
      color INTEGER NOT NULL DEFAULT 0,
      isPinned INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''';

  static const _createJobs = '''
    CREATE TABLE IF NOT EXISTS $tableJobs (
      id TEXT PRIMARY KEY,
      company TEXT NOT NULL,
      position TEXT NOT NULL,
      location TEXT NOT NULL DEFAULT '',
      salary TEXT NOT NULL DEFAULT '',
      status TEXT NOT NULL DEFAULT 'applied',
      notes TEXT NOT NULL DEFAULT '',
      appliedDate TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''';

  static const _createQrCodes = '''
    CREATE TABLE IF NOT EXISTS $tableQrCodes (
      id TEXT PRIMARY KEY,
      label TEXT NOT NULL,
      data TEXT NOT NULL,
      createdAt TEXT NOT NULL
    )
  ''';

  /// v3: indexes backing the sort orders used by the list screens.
  static const _createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_notes_pinned_updated '
        'ON $tableNotes (isPinned DESC, updatedAt DESC)',
    'CREATE INDEX IF NOT EXISTS idx_jobs_updated ON $tableJobs (updatedAt DESC)',
    'CREATE INDEX IF NOT EXISTS idx_jobs_status ON $tableJobs (status)',
    'CREATE INDEX IF NOT EXISTS idx_qr_created ON $tableQrCodes (createdAt DESC)',
  ];

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createNotes);
    await db.execute(_createJobs);
    await db.execute(_createQrCodes);
    for (final stmt in _createIndexes) {
      await db.execute(stmt);
    }
  }

  /// Applies each version step in order, so 1→4 runs the v2, v3 and v4
  /// migrations rather than skipping straight to the latest.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      switch (v) {
        case 2:
          await db.execute(_createQrCodes);
        case 3:
          for (final stmt in _createIndexes) {
            await db.execute(stmt);
          }
        case 4:
          await db.execute(
            "ALTER TABLE $tableNotes ADD COLUMN previewText TEXT NOT NULL DEFAULT ''",
          );
          await _backfillPreviews(db);
      }
    }
  }

  /// Fills `previewText` for notes written before v4.
  ///
  /// The value comes from decoding each body's Quill Delta, which SQLite has no
  /// way to do, so this is a one-time pass in Dart rather than a single UPDATE.
  /// sqflite runs `onUpgrade` inside a transaction, so a failure part-way
  /// leaves the column unadded rather than half-populated.
  static Future<void> _backfillPreviews(Database db) async {
    final rows = await db.query(tableNotes, columns: ['id', 'body']);
    if (rows.isEmpty) return;

    final batch = db.batch();
    for (final row in rows) {
      batch.update(
        tableNotes,
        {'previewText': NoteBody.toPreview(DbRead.string(row, 'body'))},
        where: 'id = ?',
        whereArgs: [DbRead.string(row, 'id')],
      );
    }
    await batch.commit(noResult: true);
  }
}
