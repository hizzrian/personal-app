import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/failure.dart';
import '../core/result.dart';
import '../data/app_database.dart';
import '../data/backup_repository.dart';
import '../models/job.dart';
import '../utils/note_body.dart';

/// Parses an exported JSON payload and inserts it.
///
/// Input is untrusted (clipboard contents), so every field is coerced to the
/// column's expected type before it reaches SQLite. Previously a `true` where
/// an INTEGER was expected surfaced as a misleading "failed to parse JSON".
class ImportService {
  ImportService(this._backup);

  final BackupRepository _backup;

  Future<Result<ImportCounts>> importFromClipboard() async {
    final ClipboardData? clip;
    try {
      clip = await Clipboard.getData(Clipboard.kTextPlain);
    } catch (e) {
      return Err(PlatformFailure('Could not read the clipboard.', cause: e));
    }

    final text = clip?.text;
    if (text == null || text.trim().isEmpty) {
      return const Err(ValidationFailure(
        'Clipboard is empty. Copy your exported JSON first.',
      ));
    }
    return importFromJson(text);
  }

  Future<Result<ImportCounts>> importFromJson(String source) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      return Err(ParseFailure('That is not valid JSON.', cause: e));
    }

    if (decoded is! Map<String, Object?>) {
      return const Err(ParseFailure('Expected a JSON object at the top level.'));
    }

    final data = decoded['data'];
    if (data is! Map<String, Object?>) {
      return const Err(ParseFailure(
        'Missing a "data" section. Use a file exported from Clarity.',
      ));
    }

    final notes = _sanitiseRows(data[AppDatabase.tableNotes], _noteRow);
    final jobs = _sanitiseRows(data[AppDatabase.tableJobs], _jobRow);
    final qrCodes = _sanitiseRows(data[AppDatabase.tableQrCodes], _qrRow);

    if (notes.isEmpty && jobs.isEmpty && qrCodes.isEmpty) {
      return const Err(ValidationFailure('No valid records found to import.'));
    }

    return _backup.importAll(notes: notes, jobs: jobs, qrCodes: qrCodes);
  }

  /// Keeps only entries that are maps with a usable id, mapped through
  /// [builder] which coerces each column to its declared type.
  List<Map<String, Object?>> _sanitiseRows(
    Object? raw,
    Map<String, Object?>? Function(Map<String, Object?> row) builder,
  ) {
    if (raw is! List) return const [];
    final result = <Map<String, Object?>>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final row = entry.cast<String, Object?>();
      final built = builder(row);
      if (built != null) result.add(built);
    }
    return result;
  }

  Map<String, Object?>? _noteRow(Map<String, Object?> row) {
    final id = _text(row['id']);
    if (id.isEmpty) return null;
    final body = _text(row['body']);
    return {
      'id': id,
      'title': _text(row['title']),
      'body': body,
      // Derived, never read from the file: a hand-edited backup could carry a
      // preview that disagrees with its body, and the list would then show
      // text the note does not contain.
      'previewText': NoteBody.toPreview(body),
      'tags': _text(row['tags']),
      'color': _int(row['color']),
      'isPinned': _boolAsInt(row['isPinned']),
      'createdAt': _isoDate(row['createdAt']),
      'updatedAt': _isoDate(row['updatedAt']),
    };
  }

  Map<String, Object?>? _jobRow(Map<String, Object?> row) {
    final id = _text(row['id']);
    if (id.isEmpty) return null;
    final status = _text(row['status']);
    return {
      'id': id,
      'company': _text(row['company']),
      'position': _text(row['position']),
      'location': _text(row['location']),
      'salary': _text(row['salary']),
      'status': Job.statuses.contains(status) ? status : 'applied',
      'notes': _text(row['notes']),
      'appliedDate': _isoDate(row['appliedDate']),
      'updatedAt': _isoDate(row['updatedAt']),
    };
  }

  Map<String, Object?>? _qrRow(Map<String, Object?> row) {
    final id = _text(row['id']);
    if (id.isEmpty) return null;
    return {
      'id': id,
      'label': _text(row['label']),
      'data': _text(row['data']),
      'createdAt': _isoDate(row['createdAt']),
    };
  }

  static String _text(Object? value) => value == null ? '' : value.toString();

  static int _int(Object? value) => switch (value) {
        int v => v,
        num v => v.toInt(),
        String v => int.tryParse(v) ?? 0,
        _ => 0,
      };

  /// Accepts real booleans as well as the 0/1 integers SQLite stores.
  static int _boolAsInt(Object? value) => switch (value) {
        bool v => v ? 1 : 0,
        num v => v != 0 ? 1 : 0,
        String v => (v == '1' || v.toLowerCase() == 'true') ? 1 : 0,
        _ => 0,
      };

  /// Normalises to ISO-8601, substituting now for anything unparseable so a
  /// bad date cannot blow up later at read time.
  static String _isoDate(Object? value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toIso8601String();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
    }
    return DateTime.now().toIso8601String();
  }
}
