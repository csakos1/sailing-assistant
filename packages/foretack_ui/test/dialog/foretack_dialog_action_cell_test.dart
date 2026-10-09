import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';

void main() {
  Future<void> pumpBar(WidgetTester tester, List<Widget> cells) =>
      tester.pumpWidget(
        MaterialApp(
          theme: foretackTheme,
          home: Scaffold(body: ForetackDialogActionBar(cells: cells)),
        ),
      );

  double opacityAbove(WidgetTester tester, String label) => tester
      .widget<Opacity>(
        // Az ancestor-kereses alulrol felfele halad: a legkozelebbi az elso.
        find
            .ancestor(of: find.text(label), matching: find.byType(Opacity))
            .first,
      )
      .opacity;

  group('ForetackDialogActionCell', () {
    testWidgets('runs its action when tapped', (tester) async {
      // ARRANGE
      var taps = 0;
      await pumpBar(tester, [
        ForetackDialogActionCell(label: 'Mentes', onPressed: () => taps++),
      ]);

      // ACT
      await tester.tap(find.text('Mentes'));

      // ASSERT
      expect(taps, 1);
      expect(opacityAbove(tester, 'Mentes'), 1);
    });

    testWidgets('dims and ignores taps without an action', (tester) async {
      // ARRANGE
      await pumpBar(tester, [
        const ForetackDialogActionCell(label: 'Feltoltes', onPressed: null),
      ]);

      // ACT
      await tester.tap(find.text('Feltoltes'));

      // ASSERT
      expect(
        opacityAbove(tester, 'Feltoltes'),
        ForetackDialogActionCell.disabledOpacity,
      );
    });

    testWidgets('shows a spinner while busy and ignores taps', (tester) async {
      // ARRANGE
      var taps = 0;
      await pumpBar(tester, [
        ForetackDialogActionCell(
          label: 'Feltoltes...',
          isBusy: true,
          onPressed: () => taps++,
        ),
      ]);

      // ACT
      await tester.tap(find.text('Feltoltes...'));

      // ASSERT: fut a muvelet, ezert nem halvanyul
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(opacityAbove(tester, 'Feltoltes...'), 1);
    });
  });

  group('ForetackDialogActionBar', () {
    testWidgets('gives every cell an equal share of the width', (
      tester,
    ) async {
      // ACT
      await pumpBar(tester, [
        ForetackDialogActionCell(label: 'Megse', onPressed: () {}),
        ForetackDialogActionCell(label: 'Feltoltes', onPressed: () {}),
      ]);

      // ASSERT
      final first = tester.getSize(find.byType(ForetackDialogActionCell).first);
      final last = tester.getSize(find.byType(ForetackDialogActionCell).last);
      expect(first.width, closeTo(last.width, 1));
      expect(first.height, 52);
    });
  });
}
