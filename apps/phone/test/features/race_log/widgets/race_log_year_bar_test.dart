import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_log/widgets/race_log_year_bar.dart';

void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    required int year,
    VoidCallback? onTap,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        home: Scaffold(
          body: RaceLogYearBar(year: year, onTap: onTap),
        ),
      ),
    );
  }

  group('RaceLogYearBar', () {
    testWidgets('shows the year and an opening affordance', (tester) async {
      await pumpBar(tester, year: 2026);

      expect(find.text('2026'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('keeps the bar 44 dp tall', (tester) async {
      // Ugyanaz a mertek, mint a detail statusz-csikja (D21).
      await pumpBar(tester, year: 2026);

      expect(tester.getSize(find.byType(InkWell)).height, 44);
    });

    testWidgets('starts the year on the 16 dp left edge', (tester) async {
      await pumpBar(tester, year: 2026);

      expect(tester.getTopLeft(find.text('2026')).dx, 16);
    });

    testWidgets('reports taps to the caller', (tester) async {
      var taps = 0;
      await pumpBar(tester, year: 2026, onTap: () => taps++);

      await tester.tap(find.byType(InkWell));

      expect(taps, 1);
    });

    testWidgets('stays inert without a tap handler', (tester) async {
      await pumpBar(tester, year: 2026);

      await tester.tap(find.byType(InkWell));

      expect(tester.takeException(), isNull);
    });
  });
}
