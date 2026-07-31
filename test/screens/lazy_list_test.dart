import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/core/dependencies.dart';
import 'package:personal_app/models/job.dart';
import 'package:personal_app/models/note.dart';
import 'package:personal_app/screens/jobs/jobs_screen.dart';
import 'package:personal_app/screens/notes/notes_screen.dart';
import 'package:personal_app/state/theme_controller.dart';

import '../support/fakes.dart';

/// These screens used to build every row eagerly inside a SliverToBoxAdapter,
/// so a large list cost a full widget tree before the first frame. The rows are
/// now built by a SliverChildBuilderDelegate; these tests pin that down by
/// asserting the built row count stays near the viewport, not the data.
void main() {
  const seedSize = 300;

  Widget harness(Widget child, {List<Note>? notes, List<Job>? jobs}) {
    return Dependencies(
      themeController: ThemeController(),
      noteRepository: FakeNoteRepository(notes),
      jobRepository: FakeJobRepository(jobs),
      qrRepository: FakeQrRepository(),
      backupRepository: FakeBackupRepository(),
      child: MaterialApp(home: child),
    );
  }

  List<Note> notes({int count = seedSize, int pinned = 0}) {
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

  List<Job> jobs({int count = seedSize}) {
    final now = DateTime(2026, 1, 1);
    return [
      for (var i = 0; i < count; i++)
        Job(
          id: 'j$i',
          company: 'Company $i',
          position: 'Position $i',
          appliedDate: now,
          updatedAt: now,
        ),
    ];
  }

  /// One [Dismissible] is created per row on both screens, so counting them
  /// counts the rows that were actually built.
  int builtRows(WidgetTester tester) =>
      tester.widgetList(find.byType(Dismissible)).length;

  /// Matches text inside a row, so a query echoed by the search field doesn't
  /// count as a result.
  Finder rowText(String text) => find.descendant(
        of: find.byType(Dismissible),
        matching: find.text(text),
      );

  /// The list itself. Selected by axis because the other scrollables on these
  /// screens — the jobs filter strip, the search field's editable — are both
  /// horizontal.
  final listScrollable = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );

  group('NotesScreen', () {
    testWidgets('builds only the rows the viewport needs', (tester) async {
      await tester.pumpWidget(harness(const NotesScreen(), notes: notes()));
      await tester.pumpAndSettle();

      expect(builtRows(tester), lessThan(30));
      expect(find.text('Note 0'), findsOneWidget);
      expect(find.text('Note $seedSize'), findsNothing);
    });

    testWidgets('builds further rows only once scrolled to', (tester) async {
      await tester.pumpWidget(harness(const NotesScreen(), notes: notes()));
      await tester.pumpAndSettle();

      expect(rowText('Note 200'), findsNothing);

      await tester.scrollUntilVisible(
        rowText('Note 200'),
        400,
        scrollable: listScrollable,
      );

      expect(rowText('Note 200'), findsOneWidget);
      expect(rowText('Note 0'), findsNothing);
      // Still bounded after scrolling — rows leaving the viewport are dropped.
      expect(builtRows(tester), lessThan(30));
    });

    testWidgets('keeps the pinned and unpinned groups separate',
        (tester) async {
      // Tall enough that all ten rows fit at once; the default 800x600 surface
      // would cull most of them and make the count meaningless.
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        harness(const NotesScreen(), notes: notes(count: 10, pinned: 3)),
      );
      await tester.pumpAndSettle();

      expect(find.text('PINNED'), findsOneWidget);
      expect(find.text('ALL NOTES'), findsOneWidget);
      expect(builtRows(tester), 10);
    });

    testWidgets('drops the group labels when nothing is pinned',
        (tester) async {
      await tester.pumpWidget(
        harness(const NotesScreen(), notes: notes(count: 5)),
      );
      await tester.pumpAndSettle();

      expect(find.text('PINNED'), findsNothing);
      expect(find.text('ALL NOTES'), findsNothing);
      expect(builtRows(tester), 5);
    });

    testWidgets('search narrows the list without rebuilding every row',
        (tester) async {
      await tester.pumpWidget(harness(const NotesScreen(), notes: notes()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Note 123');
      await tester.pumpAndSettle();

      expect(builtRows(tester), 1);
      expect(rowText('Note 123'), findsOneWidget);
    });

    testWidgets('shows the empty state when a search matches nothing',
        (tester) async {
      await tester.pumpWidget(harness(const NotesScreen(), notes: notes()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.text('No results'), findsOneWidget);
      expect(builtRows(tester), 0);
    });
  });

  group('JobsScreen', () {
    testWidgets('builds only the rows the viewport needs', (tester) async {
      await tester.pumpWidget(harness(const JobsScreen(), jobs: jobs()));
      await tester.pumpAndSettle();

      expect(builtRows(tester), lessThan(30));
      expect(rowText('Position 0'), findsOneWidget);
    });

    testWidgets('builds further rows only once scrolled to', (tester) async {
      await tester.pumpWidget(harness(const JobsScreen(), jobs: jobs()));
      await tester.pumpAndSettle();

      expect(rowText('Position 200'), findsNothing);

      await tester.scrollUntilVisible(
        rowText('Position 200'),
        400,
        scrollable: listScrollable,
      );

      expect(rowText('Position 200'), findsOneWidget);
      expect(rowText('Position 0'), findsNothing);
      expect(builtRows(tester), lessThan(30));
    });

    testWidgets('renders an empty list without rows', (tester) async {
      await tester.pumpWidget(harness(const JobsScreen(), jobs: const []));
      await tester.pumpAndSettle();

      expect(find.text('No applications yet'), findsOneWidget);
      expect(builtRows(tester), 0);
    });
  });
}
