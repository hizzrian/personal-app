import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/core/dependencies.dart';
import 'package:personal_app/models/job.dart';
import 'package:personal_app/models/job_status.dart';
import 'package:personal_app/models/note.dart';
import 'package:personal_app/screens/jobs/jobs_screen.dart';
import 'package:personal_app/screens/notes/notes_screen.dart';
import 'package:personal_app/state/theme_controller.dart';
import 'package:personal_app/utils/app_theme.dart';

import '../support/fakes.dart';

/// Captured before the design tokens landed, under the real [AppTheme] rather
/// than a bare `ThemeData`.
///
/// The existing group-card goldens deliberately use default Material styling to
/// isolate the card geometry, which means they cannot see a change to AppTheme's
/// text styles. These can: text renders as solid boxes in a test environment, so
/// a shifted font size moves the layout and a changed colour repaints it, and
/// either one breaks the comparison.
void main() {
  Widget harness(Widget screen,
      {required bool dark, List<Note>? notes, List<Job>? jobs}) {
    return Dependencies(
      themeController: ThemeController(isDarkMode: dark),
      noteRepository: FakeNoteRepository(notes),
      jobRepository: FakeJobRepository(jobs),
      qrRepository: FakeQrRepository(),
      backupRepository: FakeBackupRepository(),
      child: MaterialApp(
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: screen,
      ),
    );
  }

  List<Note> sampleNotes() {
    final now = DateTime(2026, 1, 1);
    return [
      Note(
        id: 'n0',
        title: 'A pinned note',
        body: 'preview line for the pinned note',
        tags: const ['work', 'urgent'],
        isPinned: true,
        createdAt: now,
        updatedAt: now,
      ),
      Note(
        id: 'n1',
        title: 'An ordinary note',
        body: 'preview line for the ordinary note',
        tags: const ['idea'],
        createdAt: now,
        updatedAt: now,
      ),
      Note(id: 'n2', title: '', body: '', createdAt: now, updatedAt: now),
    ];
  }

  List<Job> sampleJobs() {
    final now = DateTime(2026, 1, 1);
    return [
      for (final status in JobStatus.values)
        Job(
          id: 'j${status.name}',
          company: 'Company ${status.label}',
          position: 'Engineer',
          location: 'Remote',
          status: status,
          appliedDate: now,
          updatedAt: now,
        ),
    ];
  }

  Future<void> pumpAt(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('NotesScreen typography, $mode', (tester) async {
      await pumpAt(
        tester,
        harness(const NotesScreen(), dark: dark, notes: sampleNotes()),
      );
      await expectLater(
        find.byType(NotesScreen),
        matchesGoldenFile('goldens/typography_notes_$mode.png'),
      );
    });

    testWidgets('JobsScreen typography, $mode', (tester) async {
      await pumpAt(
        tester,
        harness(const JobsScreen(), dark: dark, jobs: sampleJobs()),
      );
      await expectLater(
        find.byType(JobsScreen),
        matchesGoldenFile('goldens/typography_jobs_$mode.png'),
      );
    });
  }
}
