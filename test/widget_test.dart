import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/core/dependencies.dart';
import 'package:personal_app/screens/settings/settings_screen.dart';
import 'package:personal_app/state/theme_controller.dart';

import 'support/fakes.dart';

void main() {
  /// Mounts a screen with fake repositories injected — the seam that Phase 2
  /// introduced. None of this was possible when screens reached for a
  /// singleton database directly.
  Widget harness(Widget child, {ThemeController? theme}) {
    return Dependencies(
      themeController: theme ?? ThemeController(),
      noteRepository: FakeNoteRepository(),
      jobRepository: FakeJobRepository(),
      qrRepository: FakeQrRepository(),
      backupRepository: FakeBackupRepository(),
      child: MaterialApp(home: child),
    );
  }

  testWidgets('settings renders its sections without touching a database',
      (tester) async {
    await tester.pumpWidget(harness(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
    expect(find.text('Clear All Data'), findsOneWidget);
  });

  testWidgets('dark mode toggle flips the controller', (tester) async {
    final theme = ThemeController();
    await tester.pumpWidget(harness(const SettingsScreen(), theme: theme));
    await tester.pumpAndSettle();

    expect(theme.isDarkMode, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(theme.isDarkMode, isTrue);
  });
}
