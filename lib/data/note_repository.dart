import 'package:sqflite/sqflite.dart';

import '../core/result.dart';
import '../models/note.dart';
import 'app_database.dart';
import 'repository_guard.dart';

abstract interface class NoteRepository {
  Future<Result<List<Note>>> all();
  Future<Result<List<Note>>> recent({int limit});
  Future<Result<int>> count();
  Future<Result<void>> save(Note note);
  Future<Result<void>> delete(String id);
  Future<Result<void>> setPinned(String id, {required bool pinned});

  /// Deletes every row using a caller-supplied executor, so a multi-table
  /// wipe can share one transaction.
  Future<void> deleteAllWithin(DatabaseExecutor executor);
}

class SqliteNoteRepository with RepositoryGuard implements NoteRepository {
  SqliteNoteRepository(this._db);

  final AppDatabase _db;

  static const _table = AppDatabase.tableNotes;
  static const _listOrder = 'isPinned DESC, updatedAt DESC';

  @override
  Future<Result<List<Note>>> all() => guard('load notes', () async {
        final db = await _db.open();
        final rows = await db.query(_table, orderBy: _listOrder);
        return rows.map(Note.fromMap).toList();
      });

  @override
  Future<Result<List<Note>>> recent({int limit = 3}) =>
      guard('load recent notes', () async {
        final db = await _db.open();
        final rows = await db.query(_table, orderBy: 'updatedAt DESC', limit: limit);
        return rows.map(Note.fromMap).toList();
      });

  @override
  Future<Result<int>> count() => guard('count notes', () async {
        final db = await _db.open();
        final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
        final value = rows.isEmpty ? null : rows.first['c'];
        return value is int ? value : 0;
      });

  @override
  Future<Result<void>> save(Note note) => guard('save note', () async {
        final db = await _db.open();
        await db.insert(
          _table,
          note.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });

  @override
  Future<Result<void>> delete(String id) => guard('delete note', () async {
        final db = await _db.open();
        await db.delete(_table, where: 'id = ?', whereArgs: [id]);
      });

  @override
  Future<Result<void>> setPinned(String id, {required bool pinned}) =>
      guard('update note', () async {
        final db = await _db.open();
        await db.update(
          _table,
          {
            'isPinned': pinned ? 1 : 0,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      });

  @override
  Future<void> deleteAllWithin(DatabaseExecutor executor) =>
      executor.delete(_table);
}
