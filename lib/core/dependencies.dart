import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../data/backup_repository.dart';
import '../data/job_repository.dart';
import '../data/note_repository.dart';
import '../data/qr_repository.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../state/theme_controller.dart';

/// Builds the object graph once and exposes it through [Provider].
///
/// Tests can construct this with fake repositories, which is what makes the
/// screens testable at all.
class Dependencies extends StatelessWidget {
  const Dependencies({
    super.key,
    required this.child,
    required this.themeController,
    this.database,
    this.noteRepository,
    this.jobRepository,
    this.qrRepository,
    this.backupRepository,
    this.exportService,
    this.importService,
  });

  final Widget child;
  final ThemeController themeController;

  // All optional: production passes nothing and gets the SQLite graph,
  // tests pass fakes for whichever collaborator they need to control.
  final AppDatabase? database;
  final NoteRepository? noteRepository;
  final JobRepository? jobRepository;
  final QrRepository? qrRepository;
  final BackupRepository? backupRepository;
  final ExportService? exportService;
  final ImportService? importService;

  @override
  Widget build(BuildContext context) {
    final db = database ?? AppDatabase();
    final notes = noteRepository ?? SqliteNoteRepository(db);
    final jobs = jobRepository ?? SqliteJobRepository(db);
    final qr = qrRepository ?? SqliteQrRepository(db);
    final backup = backupRepository ?? SqliteBackupRepository(db, notes, jobs, qr);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        Provider<AppDatabase>.value(value: db),
        Provider<NoteRepository>.value(value: notes),
        Provider<JobRepository>.value(value: jobs),
        Provider<QrRepository>.value(value: qr),
        Provider<BackupRepository>.value(value: backup),
        Provider<ExportService>.value(
          value: exportService ?? ExportService(backup),
        ),
        Provider<ImportService>.value(
          value: importService ?? ImportService(backup),
        ),
      ],
      child: child,
    );
  }
}

/// Shorthand accessors so screens read `context.notes` instead of a long
/// `Provider.of<NoteRepository>(context)`.
extension DependencyLookup on BuildContext {
  NoteRepository get notes => read<NoteRepository>();
  JobRepository get jobs => read<JobRepository>();
  QrRepository get qrCodes => read<QrRepository>();
  BackupRepository get backup => read<BackupRepository>();
  ExportService get exportService => read<ExportService>();
  ImportService get importService => read<ImportService>();
}
