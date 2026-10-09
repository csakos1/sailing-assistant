import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';

void main() {
  const actions = [
    ForetackDialogAction(label: 'Megse', value: false),
    ForetackDialogAction(label: 'Torles', value: true, isDestructive: true),
  ];

  // A dialogust egy gomb nyitja; a valaszt a `answers` listaba gyujti.
  Future<List<bool?>> pumpOpener(WidgetTester tester) async {
    final answers = <bool?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => unawaited(
                showForetackDialog<bool>(
                  context: context,
                  title: 'Torlod a versenyt?',
                  message: 'A torles vegleges.',
                  details: const [(label: 'Verseny', value: 'Siofoki')],
                  actions: actions,
                ).then(answers.add),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return answers;
  }

  group('ForetackDialog', () {
    testWidgets('shows the title, the message, the details and the actions', (
      tester,
    ) async {
      // ACT
      await pumpOpener(tester);

      // ASSERT
      expect(find.text('Torlod a versenyt?'), findsOneWidget);
      expect(find.text('A torles vegleges.'), findsOneWidget);
      expect(find.text('Verseny'), findsOneWidget);
      expect(find.text('Siofoki'), findsOneWidget);
      expect(find.text('Megse'), findsOneWidget);
      expect(find.text('Torles'), findsOneWidget);
    });

    testWidgets('paints the destructive action in the error colour', (
      tester,
    ) async {
      // ACT
      await pumpOpener(tester);

      // ASSERT
      final label = tester.widget<Text>(find.text('Torles'));
      expect(label.style?.color, foretackTheme.colorScheme.error);
    });

    testWidgets('answers with the value of the tapped action', (tester) async {
      // ARRANGE
      final answers = await pumpOpener(tester);

      // ACT
      await tester.tap(find.text('Torles'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(answers, [true]);
      expect(find.text('Torlod a versenyt?'), findsNothing);
    });

    testWidgets('closes with null on Escape', (tester) async {
      // ARRANGE
      final answers = await pumpOpener(tester);

      // ACT
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // ASSERT
      expect(answers, [null]);
    });

    testWidgets('focuses the safe action first, so Enter does not delete', (
      tester,
    ) async {
      // ARRANGE
      final answers = await pumpOpener(tester);

      // ACT
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // ASSERT
      expect(answers, [false]);
    });
  });
}
