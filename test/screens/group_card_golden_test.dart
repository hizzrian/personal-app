import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/core/dependencies.dart';
import 'package:personal_app/models/note.dart';
import 'package:personal_app/screens/notes/notes_screen.dart';
import 'package:personal_app/state/theme_controller.dart';
import 'package:personal_app/utils/app_theme.dart';

import '../support/fakes.dart';

/// The grouped-card look — rounded outer corners, hairline border, soft shadow,
/// square inner seams — used to come from one Container wrapping every row.
/// SliverGroupCard reassembles it from a DecoratedSliver plus per-row corner
/// clipping, so these goldens were captured from the old eager implementation
/// and must keep matching.
void main() {
  Widget harness(List<Note> notes, {required bool dark}) {
    return Dependencies(
      themeController: ThemeController(isDarkMode: dark),
      noteRepository: FakeNoteRepository(notes),
      jobRepository: FakeJobRepository(),
      qrRepository: FakeQrRepository(),
      backupRepository: FakeBackupRepository(),
      child: MaterialApp(
        // Uses the real theme: GroupLabel now reads its style from the
        // type scale, so a bare ThemeData would test a combination the app
        // never renders.
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: const NotesScreen(),
      ),
    );
  }

  List<Note> notes({int count = 5, int pinned = 2}) {
    final now = DateTime(2026, 1, 1);
    return [
      for (var i = 0; i < count; i++)
        Note(
          id: 'n$i',
          title: 'Note $i',
          body: 'body $i',
          isPinned: i < pinned,
          createdAt: now,
          updatedAt: now,
        ),
    ];
  }

  Future<void> pumpAt(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  testWidgets('grouped notes list, light', (tester) async {
    await pumpAt(tester, harness(notes(), dark: false));
    await expectLater(
      find.byType(NotesScreen),
      matchesGoldenFile('goldens/notes_grouped_light.png'),
    );
  });

  testWidgets('grouped notes list, dark', (tester) async {
    await pumpAt(tester, harness(notes(), dark: true));
    await expectLater(
      find.byType(NotesScreen),
      matchesGoldenFile('goldens/notes_grouped_dark.png'),
    );
  });

  testWidgets('single-row group rounds both ends', (tester) async {
    await pumpAt(tester, harness(notes(count: 1, pinned: 0), dark: false));
    await expectLater(
      find.byType(NotesScreen),
      matchesGoldenFile('goldens/notes_single_row.png'),
    );
  });
}
