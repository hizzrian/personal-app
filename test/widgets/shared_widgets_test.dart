import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/models/job_status.dart';
import 'package:personal_app/utils/app_theme.dart';
import 'package:personal_app/widgets/confirm_dialog.dart';
import 'package:personal_app/widgets/empty_state.dart';
import 'package:personal_app/widgets/status_badge.dart';

/// These three widgets existed unused while four screens hand-rolled the same
/// markup. Adopting them meant rewriting each to match what the screens drew,
/// so the tests pin the behaviour the screens depend on.
void main() {
  Widget host(Widget child, {bool dark = false}) => MaterialApp(
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: Scaffold(body: child),
      );

  group('ConfirmDialog', () {
    Future<bool?> open(WidgetTester tester, {String? message}) async {
      bool? answer;
      await tester.pumpWidget(host(Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            answer = await ConfirmDialog.show(
              context,
              title: 'Delete note?',
              message: message,
              confirmLabel: 'Delete',
            );
          },
          child: const Text('open'),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return answer;
    }

    testWidgets('reports the choice back to the caller', (tester) async {
      late bool answer;
      await tester.pumpWidget(host(Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            answer = await ConfirmDialog.show(context, title: 'Delete note?');
          },
          child: const Text('open'),
        ),
      )));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(answer, isTrue);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(answer, isFalse);
    });

    testWidgets('a dismissed dialog counts as declined', (tester) async {
      late bool answer;
      await tester.pumpWidget(host(Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            answer = await ConfirmDialog.show(context, title: 'Delete note?');
          },
          child: const Text('open'),
        ),
      )));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      // Tapping the barrier dismisses without an answer.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(answer, isFalse);
    });

    testWidgets('omits the content when no message is given', (tester) async {
      await open(tester);
      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.content, isNull);
    });

    testWidgets('shows the content when a message is given', (tester) async {
      await open(tester, message: 'This cannot be undone.');
      expect(find.text('This cannot be undone.'), findsOneWidget);
    });

    testWidgets('renders on the dark surface in dark mode', (tester) async {
      // The pre-adoption version hardcoded the light palette, which would have
      // put dark text on a near-white dialog here.
      await tester.pumpWidget(host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => ConfirmDialog.show(context, title: 'Delete?'),
            child: const Text('open'),
          ),
        ),
        dark: true,
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(find.text('Delete?'));
      expect(title.style?.color, isNot(AppTheme.onSurface));
    });
  });

  group('EmptyState', () {
    testWidgets('shows the title alone by default', (tester) async {
      await tester.pumpWidget(host(
        const EmptyState(icon: Icons.note_alt_outlined, title: 'No notes yet'),
      ));

      expect(find.text('No notes yet'), findsOneWidget);
      expect(find.byIcon(Icons.note_alt_outlined), findsOneWidget);
    });

    testWidgets('adds the subtitle when one is given', (tester) async {
      await tester.pumpWidget(host(
        const EmptyState(
          icon: Icons.qr_code_2_rounded,
          title: 'No saved QR codes',
          subtitle: 'Add one to show it quickly later',
        ),
      ));

      expect(find.text('Add one to show it quickly later'), findsOneWidget);
    });
  });

  group('StatusBadge', () {
    testWidgets('labels and colours itself from the status', (tester) async {
      await tester.pumpWidget(host(const StatusBadge(status: JobStatus.offer)));

      expect(find.text('Offer'), findsOneWidget);
      final label = tester.widget<Text>(find.text('Offer'));
      expect(label.style?.color, Color(JobStatus.offer.colorValue));
    });

    testWidgets('every status renders', (tester) async {
      for (final status in JobStatus.values) {
        await tester.pumpWidget(host(StatusBadge(status: status)));
        expect(find.text(status.label), findsOneWidget, reason: status.name);
      }
    });
  });
}
