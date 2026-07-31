import 'package:sqflite/sqflite.dart';

import '../core/result.dart';
import '../models/qr_item.dart';
import 'app_database.dart';
import 'repository_guard.dart';

abstract interface class QrRepository {
  Future<Result<List<QrItem>>> all();
  Future<Result<int>> count();
  Future<Result<void>> save(QrItem item);
  Future<Result<void>> delete(String id);
  Future<void> deleteAllWithin(DatabaseExecutor executor);
}

class SqliteQrRepository with RepositoryGuard implements QrRepository {
  SqliteQrRepository(this._db);

  final AppDatabase _db;

  static const _table = AppDatabase.tableQrCodes;

  @override
  Future<Result<List<QrItem>>> all() => guard('load QR codes', () async {
        final db = await _db.open();
        final rows = await db.query(_table, orderBy: 'createdAt DESC');
        return rows.map(QrItem.fromMap).toList();
      });

  @override
  Future<Result<int>> count() => guard('count QR codes', () async {
        final db = await _db.open();
        final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
        final value = rows.isEmpty ? null : rows.first['c'];
        return value is int ? value : 0;
      });

  @override
  Future<Result<void>> save(QrItem item) => guard('save QR code', () async {
        final db = await _db.open();
        await db.insert(
          _table,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });

  @override
  Future<Result<void>> delete(String id) => guard('delete QR code', () async {
        final db = await _db.open();
        await db.delete(_table, where: 'id = ?', whereArgs: [id]);
      });

  @override
  Future<void> deleteAllWithin(DatabaseExecutor executor) =>
      executor.delete(_table);
}
