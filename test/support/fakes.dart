import 'package:personal_app/core/result.dart';
import 'package:personal_app/data/backup_repository.dart';
import 'package:personal_app/data/job_repository.dart';
import 'package:personal_app/data/note_repository.dart';
import 'package:personal_app/data/qr_repository.dart';
import 'package:personal_app/models/job.dart';
import 'package:personal_app/models/note.dart';
import 'package:personal_app/models/qr_item.dart';
import 'package:sqflite/sqflite.dart';

/// In-memory repositories for widget tests — no SQLite, no plugins.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository([List<Note>? seed]) : items = [...?seed];

  final List<Note> items;

  @override
  Future<Result<List<Note>>> all() async => Ok(List.unmodifiable(items));

  @override
  Future<Result<List<Note>>> recent({int limit = 3}) async =>
      Ok(items.take(limit).toList());

  @override
  Future<Result<int>> count() async => Ok(items.length);

  @override
  Future<Result<void>> save(Note note) async {
    items.removeWhere((n) => n.id == note.id);
    items.insert(0, note);
    return const Ok(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    items.removeWhere((n) => n.id == id);
    return const Ok(null);
  }

  @override
  Future<Result<void>> setPinned(String id, {required bool pinned}) async {
    final index = items.indexWhere((n) => n.id == id);
    if (index != -1) {
      items[index] = items[index].copyWith(isPinned: pinned);
    }
    return const Ok(null);
  }

  @override
  Future<void> deleteAllWithin(DatabaseExecutor executor) async => items.clear();
}

class FakeJobRepository implements JobRepository {
  FakeJobRepository([List<Job>? seed]) : items = [...?seed];

  final List<Job> items;

  @override
  Future<Result<List<Job>>> all() async => Ok(List.unmodifiable(items));

  @override
  Future<Result<List<Job>>> recent({int limit = 2}) async =>
      Ok(items.take(limit).toList());

  @override
  Future<Result<int>> count() async => Ok(items.length);

  @override
  Future<Result<void>> save(Job job) async {
    items.removeWhere((j) => j.id == job.id);
    items.insert(0, job);
    return const Ok(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    items.removeWhere((j) => j.id == id);
    return const Ok(null);
  }

  @override
  Future<void> deleteAllWithin(DatabaseExecutor executor) async => items.clear();
}

class FakeQrRepository implements QrRepository {
  FakeQrRepository([List<QrItem>? seed]) : items = [...?seed];

  final List<QrItem> items;

  @override
  Future<Result<List<QrItem>>> all() async => Ok(List.unmodifiable(items));

  @override
  Future<Result<int>> count() async => Ok(items.length);

  @override
  Future<Result<void>> save(QrItem item) async {
    items.removeWhere((q) => q.id == item.id);
    items.insert(0, item);
    return const Ok(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    items.removeWhere((q) => q.id == id);
    return const Ok(null);
  }

  @override
  Future<void> deleteAllWithin(DatabaseExecutor executor) async => items.clear();
}

class FakeBackupRepository implements BackupRepository {
  bool clearAllCalled = false;

  @override
  Future<Result<Map<String, List<Map<String, Object?>>>>> exportAll() async =>
      const Ok({});

  @override
  Future<Result<ImportCounts>> importAll({
    required List<Map<String, Object?>> notes,
    required List<Map<String, Object?>> jobs,
    required List<Map<String, Object?>> qrCodes,
  }) async =>
      Ok(ImportCounts(
        notes: notes.length,
        jobs: jobs.length,
        qrCodes: qrCodes.length,
      ));

  @override
  Future<Result<void>> clearAll() async {
    clearAllCalled = true;
    return const Ok(null);
  }
}
