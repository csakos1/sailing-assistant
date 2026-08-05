import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_log/widgets/race_log_month_header.dart';

void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    required String monthLabel,
    required String countLabel,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        home: Scaffold(
          body: RaceLogMonthHeader(
            monthLabel: monthLabel,
            countLabel: countLabel,
          ),
        ),
      ),
    );
  }

  group('RaceLogMonthHeader', () {
    testWidgets('upper cases the month label', (tester) async {
      // A verzalositas a widget dolga, nem az ARB-e (D43).
      await pumpHeader(tester, monthLabel: 'majus', countLabel: '3');

      expect(find.text('MAJUS'), findsOneWidget);
      expect(find.text('majus'), findsNothing);
    });

    testWidgets('shows the count label as given', (tester) async {
      await pumpHeader(tester, monthLabel: 'majus', countLabel: '12');

      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('puts the count to the right of the label', (tester) async {
      await pumpHeader(tester, monthLabel: 'aprilis', countLabel: '2');

      final labelRight = tester.getTopRight(find.text('APRILIS')).dx;
      final countLeft = tester.getTopLeft(find.text('2')).dx;

      expect(countLeft, greaterThanOrEqualTo(labelRight));
    });

    testWidgets('starts the label on the row padding', (tester) async {
      // Ugyanaz a 16 dp bal el, mint a naplo-soron (D37).
      await pumpHeader(tester, monthLabel: 'majus', countLabel: '3');

      expect(tester.getTopLeft(find.text('MAJUS')).dx, 16);
    });
  });
}
