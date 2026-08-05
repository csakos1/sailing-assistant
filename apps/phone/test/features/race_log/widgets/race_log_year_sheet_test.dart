import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_log/widgets/race_log_year_sheet.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.9, longitude: 18.05),
  );

  Race finishedRace({required String id, required int year}) {
    return Race.create(
      id: id,
      name: 'Verseny $id',
      marks: const [mark],
    ).start(at: DateTime(year, 5, 1, 10)).finish(at: DateTime(year, 5, 1, 12));
  }

  RaceLogYear logYear({required int year, required int raceCount}) {
    return RaceLogYear(
      year: year,
      months: [
        RaceLogMonth(
          month: 5,
          races: [
            for (var index = 0; index < raceCount; index++)
              finishedRace(id: '$year-$index', year: year),
          ],
        ),
      ],
    );
  }

  // A lapot a valos uton nyitjuk meg, hogy a pop szerzodese is
  // tesztelve legyen: showModalBottomSheet<int> adja vissza az evet.
  Future<int?> openSheet(
    WidgetTester tester, {
    required List<RaceLogYear> years,
    required int selectedYear,
  }) async {
    int? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                picked = await showModalBottomSheet<int>(
                  context: context,
                  builder: (_) => RaceLogYearSheet(
                    title: 'ev',
                    years: years,
                    selectedYear: selectedYear,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return picked;
  }

  group('RaceLogYearSheet', () {
    testWidgets('lists every year with its race count', (tester) async {
      await openSheet(
        tester,
        years: [
          logYear(year: 2026, raceCount: 3),
          logYear(year: 2024, raceCount: 1),
        ],
        selectedYear: 2026,
      );

      expect(find.text('2026'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('upper cases the sheet title', (tester) async {
      await openSheet(
        tester,
        years: [logYear(year: 2026, raceCount: 1)],
        selectedYear: 2026,
      );

      expect(find.text('EV'), findsOneWidget);
    });

    testWidgets('paints the selected year with the primary colour', (
      tester,
    ) async {
      await openSheet(
        tester,
        years: [
          logYear(year: 2026, raceCount: 1),
          logYear(year: 2024, raceCount: 1),
        ],
        selectedYear: 2024,
      );

      final selected = tester.widget<Text>(find.text('2024'));
      final other = tester.widget<Text>(find.text('2026'));

      expect(selected.style?.color, foretackTheme.colorScheme.primary);
      expect(other.style?.color, foretackTheme.colorScheme.onSurface);
    });

    testWidgets('shows a single row for a single year', (tester) async {
      // D35: egy evnel is latszik a sav, es a lap egy mar kivalasztott
      // sort mutat.
      await openSheet(
        tester,
        years: [logYear(year: 2026, raceCount: 2)],
        selectedYear: 2026,
      );

      expect(find.text('2026'), findsOneWidget);
    });
  });

  group('RaceLogYearSheet selection', () {
    testWidgets('returns the year the user tapped', (tester) async {
      int? picked;
      await tester.pumpWidget(
        MaterialApp(
          theme: foretackTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  picked = await showModalBottomSheet<int>(
                    context: context,
                    builder: (_) => RaceLogYearSheet(
                      title: 'ev',
                      years: [
                        logYear(year: 2026, raceCount: 1),
                        logYear(year: 2024, raceCount: 1),
                      ],
                      selectedYear: 2026,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2024'));
      await tester.pumpAndSettle();

      expect(picked, 2024);
    });
  });
}
