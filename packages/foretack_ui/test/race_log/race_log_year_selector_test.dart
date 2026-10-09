import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';

void main() {
  Future<void> pumpSelector(
    WidgetTester tester, {
    required List<RaceLogYearEntry> years,
    String? leadingLabel,
    RaceLogYearOption? allYearsOption,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        home: Scaffold(
          body: RaceLogYearSelector(
            years: years,
            leadingLabel: leadingLabel,
            allYearsOption: allYearsOption,
            countLabel: '6 VERSENY',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<RaceLogYearEntry> yearsWith(
    int? selected, {
    void Function(String label)? onPick,
  }) => [
    for (final year in [2026, 2025, 2024])
      (
        label: '$year',
        isSelected: year == selected,
        onSelected: () => onPick?.call('$year'),
      ),
  ];

  // A felirat tenyleges betumerete: az orokolt (animalt) stilus a sajattal
  // osszefesulve.
  double? fontSizeOf(WidgetTester tester, String label) {
    final finder = find.text(label);
    final inherited = DefaultTextStyle.of(tester.element(finder)).style;
    return inherited.merge(tester.widget<Text>(finder).style).fontSize;
  }

  double leftOf(WidgetTester tester, String label) =>
      tester.getTopLeft(find.text(label)).dx;

  group('RaceLogYearSelector', () {
    testWidgets('shows every year and the count', (tester) async {
      // ACT
      await pumpSelector(tester, years: yearsWith(2025));

      // ASSERT
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
      expect(find.text('6 VERSENY'), findsOneWidget);
    });

    testWidgets('keeps the years in order when an older one is selected', (
      tester,
    ) async {
      // ACT: ADR 0048 Addendum 7 N1
      await pumpSelector(tester, years: yearsWith(2025));

      // ASSERT
      expect(leftOf(tester, '2026'), lessThan(leftOf(tester, '2025')));
      expect(leftOf(tester, '2025'), lessThan(leftOf(tester, '2024')));
    });

    testWidgets('grows only the selected year', (tester) async {
      // ACT
      await pumpSelector(tester, years: yearsWith(2025));

      // ASSERT
      expect(fontSizeOf(tester, '2025'), numeralMediumStyle.fontSize);
      expect(fontSizeOf(tester, '2026'), numeralMicroStyle.fontSize);
      expect(fontSizeOf(tester, '2024'), numeralMicroStyle.fontSize);
    });

    testWidgets('keeps the count label at the left edge', (tester) async {
      // ACT
      await pumpSelector(tester, years: yearsWith(2024));

      // ASSERT
      expect(
        leftOf(tester, '6 VERSENY'),
        lessThanOrEqualTo(leftOf(tester, '2026')),
      );
    });

    testWidgets('reports a tapped year but not the selected one', (
      tester,
    ) async {
      // ARRANGE
      final picked = <String>[];
      await pumpSelector(tester, years: yearsWith(2025, onPick: picked.add));

      // ACT
      await tester.tap(find.text('2024'));
      await tester.tap(find.text('2025'));

      // ASSERT
      expect(picked, ['2024']);
    });

    testWidgets('leads with the range when all years are shown', (
      tester,
    ) async {
      // ACT
      await pumpSelector(
        tester,
        years: yearsWith(null),
        leadingLabel: '2024–2026',
      );

      // ASSERT
      expect(fontSizeOf(tester, '2024–2026'), numeralMediumStyle.fontSize);
      expect(leftOf(tester, '2024–2026'), lessThan(leftOf(tester, '2026')));
      expect(fontSizeOf(tester, '2026'), numeralMicroStyle.fontSize);
    });

    testWidgets('offers the all-years option when given', (tester) async {
      // ARRANGE
      var allTaps = 0;
      await pumpSelector(
        tester,
        years: yearsWith(2026),
        allYearsOption: (label: 'ÖSSZES', onSelected: () => allTaps++),
      );

      // ACT
      await tester.tap(find.text('ÖSSZES'));

      // ASSERT
      expect(allTaps, 1);
    });

    testWidgets('has no all-years option without one', (tester) async {
      await pumpSelector(tester, years: yearsWith(2026));

      expect(find.text('ÖSSZES'), findsNothing);
    });
  });
}
