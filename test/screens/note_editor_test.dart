import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/core/dependencies.dart';
import 'package:personal_app/models/note.dart';
import 'package:personal_app/screens/notes/note_editor_screen.dart';
import 'package:personal_app/state/theme_controller.dart';
import 'package:personal_app/utils/app_theme.dart';

import '../support/fakes.dart';

/// Guards the split of the editor's 343-line build method into named widgets.
/// Each assertion here is about a piece that moved.
void main() {
  late FakeNoteRepository notes;

  setUp(() => notes = FakeNoteRepository());

  Widget harness(Note? note) {
    return Dependencies(
      themeController: ThemeController(isDarkMode: false),
      noteRepository: notes,
      jobRepository: FakeJobRepository(),
      qrRepository: FakeQrRepository(),
      backupRepository: FakeBackupRepository(),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        // Mirrors main.dart: the Quill toolbar reads its tooltips from these,
        // and throws without the delegate.
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: NoteEditorScreen(note: note),
      ),
    );
  }

  String delta(String text) => jsonEncode([
        {'insert': text.endsWith('\n') ? text : '$text\n'},
      ]);

  Note noteWith(
      {String title = 'Title',
      String body = '',
      List<String> tags = const []}) {
    final now = DateTime(2026, 1, 1);
    return Note(
      id: 'n1',
      title: title,
      body: body.isEmpty ? '' : delta(body),
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets('opens an existing note with its title, tags and body',
      (tester) async {
    await tester.pumpWidget(harness(
      noteWith(title: 'My note', body: 'hello world', tags: const ['work']),
    ));
    await tester.pumpAndSettle();

    expect(find.text('My note'), findsOneWidget);
    expect(find.text('work'), findsOneWidget);
    expect(find.text('Add Tag'), findsOneWidget);
  });

  testWidgets('a new note starts empty and reports no words', (tester) async {
    await tester.pumpWidget(harness(null));
    await tester.pumpAndSettle();

    expect(find.text('0 words · < 1 min read'), findsOneWidget);
    // The autosave indicator starts settled rather than mid-save.
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Saving...'), findsNothing);
  });

  testWidgets('the word count reflects the loaded body', (tester) async {
    await tester.pumpWidget(harness(noteWith(body: 'one two three four')));
    await tester.pumpAndSettle();

    expect(find.text('4 words · 1 min read'), findsOneWidget);
  });

  testWidgets('typing a title flips the indicator to saving', (tester) async {
    await tester.pumpWidget(harness(null));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Draft');
    await tester.pump();

    expect(find.text('Saving...'), findsOneWidget);
  });

  testWidgets('Done writes the note through the repository', (tester) async {
    await tester.pumpWidget(harness(null));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Saved from a test');
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(notes.items, hasLength(1));
    expect(notes.items.single.title, 'Saved from a test');
  });

  testWidgets('an empty note is discarded rather than saved', (tester) async {
    await tester.pumpWidget(harness(null));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(notes.items, isEmpty);
  });

  testWidgets('long-pressing a tag removes it', (tester) async {
    await tester.pumpWidget(harness(noteWith(tags: const ['work', 'idea'])));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('work'));
    await tester.pumpAndSettle();

    expect(find.text('work'), findsNothing);
    expect(find.text('idea'), findsOneWidget);
  });
}
