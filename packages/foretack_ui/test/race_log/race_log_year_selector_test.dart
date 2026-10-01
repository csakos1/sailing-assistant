import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';

void main() {
  Future<void> pumpSelector(
    WidgetTester tester, {
    required List<RaceLogYearOption> options,
    RaceLogYearOption? allYearsOption,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: foretackTheme,
      home: Scaffold(
        body: RaceLogYearSelector(
          selectedLabel: '2026',
          options: options,
          allYearsOption: allYearsOption,
          countLabel: '6 VERSENY',
        ),
      ),
    ),
  );

  group('RaceLogYearSelector', () {
    testWidgets('shows the selected year, the others and the count', (
      tester,
    ) async {
      // ACT
      await pumpSelector(
        tester,
        options: [
          (label: '2025', onSelected: () {}),
          (label: '2024', onSelected: () {}),
        ],
      );

      // ASSERT
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
      expect(find.text('6 VERSENY'), findsOneWidget);
    });

    testWidgets('reports the tapped year', (tester) async {
      // ARRANGE
      final picked = <String>[];
      await pumpSelector(
        tester,
        options: [
          (label: '2025', onSelected: () => picked.add('2025')),
          (label: '2024', onSelected: () => picked.add('2024')),
        ],
      );

      // ACT
      await tester.tap(find.text('2024'));

      // ASSERT
      expect(picked, ['2024']);
    });

    testWidgets('offers the all-years option when given', (tester) async {
      // ARRANGE
      var allTaps = 0;
      await pumpSelector(
        tester,
        options: const [],
        allYearsOption: (label: 'ÖSSZES', onSelected: () => allTaps++),
      );

      // ACT
      await tester.tap(find.text('ÖSSZES'));

      // ASSERT
      expect(allTaps, 1);
    });

    testWidgets('has no all-years option without one', (tester) async {
      await pumpSelector(tester, options: const []);

      expect(find.byType(InkWell), findsNothing);
    });
  });
}
