import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_log/widgets/race_log_row.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.9, longitude: 18.05),
  );

  // A nap-szam a HELYI idot koveti, ezert a fixtura is lokalis
  // DateTime-mal keszul: igy a varakozas idozonatol fuggetlen.
  Race finishedRace({required String name, required int day}) {
    return Race.create(id: 'r1', name: name, marks: const [mark])
        .start(at: DateTime(2026, 5, day, 10))
        .finish(at: DateTime(2026, 5, day, 14));
  }

  Future<void> pumpRow(
    WidgetTester tester,
    Race race, {
    VoidCallback? onTap,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        home: Scaffold(
          body: RaceLogRow(race: race, onTap: onTap),
        ),
      ),
    );
  }

  group('RaceLogRow content', () {
    testWidgets('pads the day number to two digits', (tester) async {
      await pumpRow(tester, finishedRace(name: 'Alfa', day: 2));

      expect(find.text('02'), findsOneWidget);
    });

    testWidgets('keeps a two digit day unpadded', (tester) async {
      await pumpRow(tester, finishedRace(name: 'Alfa', day: 27));

      expect(find.text('27'), findsOneWidget);
    });

    testWidgets('shows the race name and a chevron', (tester) async {
      await pumpRow(tester, finishedRace(name: 'Kekszalag', day: 2));

      expect(find.text('Kekszalag'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('falls back to a placeholder without a finish time', (
      tester,
    ) async {
      // A naploba ilyen sor nem kerul, de a widget nem dobhat a vizen.
      final unfinished = Race.create(
        id: 'r1',
        name: 'Alfa',
        marks: const [mark],
      );

      await pumpRow(tester, unfinished);

      expect(find.text('--'), findsOneWidget);
    });
  });

  group('RaceLogRow geometry', () {
    testWidgets('centres the day slot at 30 dp and starts the name at 60', (
      tester,
    ) async {
      // Ez a D37 szamtana: 16 + 14 = 30, illetve 16 + 28 + 16 = 60.
      await pumpRow(tester, finishedRace(name: 'Alfa', day: 2));

      expect(tester.getCenter(find.text('02')).dx, 30);
      expect(tester.getTopLeft(find.text('Alfa')).dx, 60);
    });

    testWidgets('keeps the row 56 dp tall', (tester) async {
      await pumpRow(tester, finishedRace(name: 'Alfa', day: 2));

      expect(tester.getSize(find.byType(InkWell)).height, 56);
    });
  });

  group('RaceLogRow interaction', () {
    testWidgets('reports taps to the caller', (tester) async {
      var taps = 0;
      await pumpRow(
        tester,
        finishedRace(name: 'Alfa', day: 2),
        onTap: () => taps++,
      );

      await tester.tap(find.byType(InkWell));

      expect(taps, 1);
    });

    testWidgets('stays inert without a tap handler', (tester) async {
      await pumpRow(tester, finishedRace(name: 'Alfa', day: 2));

      await tester.tap(find.byType(InkWell));

      expect(tester.takeException(), isNull);
    });
  });
}
