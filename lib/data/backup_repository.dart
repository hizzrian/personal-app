import 'package:sqflite/sqflite.dart';

import '../core/result.dart';
import 'app_database.dart';
import 'job_repository.dart';
import 'note_repository.dart';
import 'qr_repository.dart';
import 'repository_guard.dart';

/// Row counts inserted by an import.
class ImportCounts {
  const ImportCounts({this.notes = 0, this.jobs = 0, this.qrCodes = 0});
  final int notes;
  final int jobs;
  final int qrCodes;

  int get total => notes + jobs + qrCodes;
}

/// Cross-table operations: whole-database export, import, and wipe.
abstract interface class BackupRepository {
  /// Every row from every table, as raw maps ready for JSON encoding.
  Future<Result<Map<String, List<Map<String, Object?>>>>> exportAll();

  /// Inserts rows, skipping ids that already exist. Runs in one transaction.
  Future<Result<ImportCounts>> importAll({
    required List<Map<String, Object?>> notes,
    required List<Map<String, Object?>> jobs,
    required List<Map<String, Object?>> qrCodes,
  });

  /// Clears all three tables atomically.
  Future<Result<void>> clearAll();
}

class SqliteBackupRepository with RepositoryGuard implements BackupRepository {
  SqliteBackupRepository(this._db, this._notes, this._jobs, this._qr);

  final AppDatabase _db;
  final NoteRepository _notes;
  final JobRepository _jobs;
  final QrRepository _qr;

  @override
  Future<Result<Map<String, List<Map<String, Object?>>>>> exportAll() =>
      guard('export data', () async {
        final db = await _db.open();
        return {
          AppDatabase.tableNotes:
              await db.query(AppDatabase.tableNotes, orderBy: 'updatedAt DESC'),
          AppDatabase.tableJobs:
              await db.query(AppDatabase.tableJobs, orderBy: 'updatedAt DESC'),
          AppDatabase.tableQrCodes:
              await db.query(AppDatabase.tableQrCodes, orderBy: 'createdAt DESC'),
        };
      });

  @override
  Future<Result<ImportCounts>> importAll({
    required List<Map<String, Object?>> notes,
    required List<Map<String, Object?>> jobs,
    required List<Map<String, Object?>> qrCodes,
  }) =>
      guard('import data', () async {
        final db = await _db.open();

        // One transaction: a mid-import failure rolls everything back rather
        // than leaving the database half-populated.
        return db.transaction((txn) async {
          final before = await _counts(txn);

          await _insertAllIgnoring(txn, AppDatabase.tableNotes, notes);
          await _insertAllIgnoring(txn, AppDatabase.tableJobs, jobs);
          await _insertAllIgnoring(txn, AppDatabase.tableQrCodes, qrCodes);

          final after = await _counts(txn);
          return ImportCounts(
            notes: after.notes - before.notes,
            jobs: after.jobs - before.jobs,
            qrCodes: after.qrCodes - before.qrCodes,
          );
        });
      });

  /// `INSERT OR IGNORE` per row, so existing ids are skipped without the
  /// SELECT-then-INSERT round trip the previous implementation used.
  Future<void> _insertAllIgnoring(
    DatabaseExecutor executor,
    String table,
    List<Map<String, Object?>> rows,
  ) async {
    for (final row in rows) {
      if (row.isEmpty) continue;
      final columns = row.keys.toList();
      final placeholders = List.filled(columns.length, '?').join(', ');
      await executor.rawInsert(
        'INSERT OR IGNORE INTO $table (${columns.join(', ')}) '
        'VALUES ($placeholders)',
        [for (final c in columns) row[c]],
      );
    }
  }

  /// Row counts for all three tables, used to derive how many rows an import
  /// actually inserted (INSERT OR IGNORE gives no reliable per-row signal
  /// when the primary key is TEXT).
  Future<ImportCounts> _counts(DatabaseExecutor executor) async {
    Future<int> countOf(String table) async {
      final rows = await executor.rawQuery('SELECT COUNT(*) AS c FROM $table');
      final value = rows.isEmpty ? null : rows.first['c'];
      return value is int ? value : 0;
    }

    return ImportCounts(
      notes: await countOf(AppDatabase.tableNotes),
      jobs: await countOf(AppDatabase.tableJobs),
      qrCodes: await countOf(AppDatabase.tableQrCodes),
    );
  }

  @override
  Future<Result<void>> clearAll() => guard('clear data', () async {
        final db = await _db.open();
        await db.transaction((txn) async {
          await _notes.deleteAllWithin(txn);
          await _jobs.deleteAllWithin(txn);
          await _qr.deleteAllWithin(txn);
        });
      });
}
