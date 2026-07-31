import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/failure.dart';
import '../core/result.dart';
import '../data/app_database.dart';
import '../data/backup_repository.dart';

/// Writes a JSON snapshot of all data and hands it to the share sheet.
class ExportService {
  ExportService(this._backup);

  final BackupRepository _backup;

  static final _timestamp = DateFormat('yyyyMMdd_HHmmss');
  static const _appVersion = '1.0.0';

  Future<Result<void>> exportToShareSheet() async {
    final snapshot = await _backup.exportAll();
    if (snapshot case Err(:final failure)) return Err(failure);

    final data = (snapshot as Ok<Map<String, List<Map<String, Object?>>>>).value;

    File? file;
    try {
      final payload = {
        'exportedAt': DateTime.now().toIso8601String(),
        'appVersion': _appVersion,
        'data': data,
        'summary': {
          'totalNotes': data[AppDatabase.tableNotes]?.length ?? 0,
          'totalJobs': data[AppDatabase.tableJobs]?.length ?? 0,
          'totalQrCodes': data[AppDatabase.tableQrCodes]?.length ?? 0,
        },
      };

      final json = const JsonEncoder.withIndent('  ').convert(payload);
      final dir = await getTemporaryDirectory();
      file = File('${dir.path}/clarity_export_${_timestamp.format(DateTime.now())}.json');
      await file.writeAsString(json);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Clarity export',
        text: 'My Clarity app data export',
      );
      return const Ok(null);
    } catch (e) {
      return Err(PlatformFailure('Could not export data.', cause: e));
    } finally {
      // The share sheet has already copied the payload by the time it returns,
      // so the temp file would otherwise accumulate a full copy of all user
      // data on every export.
      await _deleteQuietly(file);
    }
  }

  Future<void> _deleteQuietly(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best effort; the OS clears the temp dir eventually.
    }
  }
}
