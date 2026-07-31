import 'package:sqflite/sqflite.dart';

import '../core/result.dart';
import '../models/job.dart';
import 'app_database.dart';
import 'repository_guard.dart';

abstract interface class JobRepository {
  Future<Result<List<Job>>> all();
  Future<Result<List<Job>>> recent({int limit});
  Future<Result<int>> count();
  Future<Result<void>> save(Job job);
  Future<Result<void>> delete(String id);
  Future<void> deleteAllWithin(DatabaseExecutor executor);
}

class SqliteJobRepository with RepositoryGuard implements JobRepository {
  SqliteJobRepository(this._db);

  final AppDatabase _db;

  static const _table = AppDatabase.tableJobs;

  @override
  Future<Result<List<Job>>> all() => guard('load applications', () async {
        final db = await _db.open();
        final rows = await db.query(_table, orderBy: 'updatedAt DESC');
        return rows.map(Job.fromMap).toList();
      });

  @override
  Future<Result<List<Job>>> recent({int limit = 2}) =>
      guard('load recent applications', () async {
        final db = await _db.open();
        final rows = await db.query(_table, orderBy: 'updatedAt DESC', limit: limit);
        return rows.map(Job.fromMap).toList();
      });

  @override
  Future<Result<int>> count() => guard('count applications', () async {
        final db = await _db.open();
        final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
        final value = rows.isEmpty ? null : rows.first['c'];
        return value is int ? value : 0;
      });

  @override
  Future<Result<void>> save(Job job) => guard('save application', () async {
        final db = await _db.open();
        await db.insert(
          _table,
          job.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });

  @override
  Future<Result<void>> delete(String id) => guard('delete application', () async {
        final db = await _db.open();
        await db.delete(_table, where: 'id = ?', whereArgs: [id]);
      });

  @override
  Future<void> deleteAllWithin(DatabaseExecutor executor) =>
      executor.delete(_table);
}
