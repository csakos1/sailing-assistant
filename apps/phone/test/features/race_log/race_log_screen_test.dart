import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_log/race_log_screen.dart';
import 'package:phone/features/race_log/widgets/race_log_month_header.dart';
import 'package:phone/features/race_log/widgets/race_log_row.dart';
import 'package:phone/features/race_log/widgets/race_log_stats_strip.dart';
import 'package:phone/features/race_log/widgets/race_log_year_bar.dart';
import 'package:phone/features/race_log/widgets/race_log_year_sheet.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/race_log_provider.dart';
import 'package:phone/providers/track_sample_reader_provider.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.9, longitude: 18.05),
  );

  // Minden fixtura-verseny pontosan negy oras, hogy a vizen toltott ido
  // varhato erteke szamolhato legyen.
  Race finishedRace({
    required String id,
    required int year,
    required int month,
  }) {
    return Race.create(id: id, name: id, marks: const [mark])
        .start(at: DateTime(year, month, 2, 10))
        .finish(at: DateTime(year, month, 2, 14));
  }

  RaceLogYear logYear({
    required int year,
    required Map<int, List<String>> byMonth,
  }) {
    return RaceLogYear(
      year: year,
      months: [
        for (final entry in byMonth.entries)
          RaceLogMonth(
            month: entry.key,
            races: [
              for (final id in entry.value)
                finishedRace(id: id, year: year, month: entry.key),
            ],
          ),
      ],
    );
  }

  // A minta-olvasot MINDIG felul kell irni: enelkul a stat-csik providere
  // a valos Drift adatbazist epitene fel a teszt-kornyezetben.
  Future<void> pumpScreen(
    WidgetTester tester, {
    required AsyncValue<List<RaceLogYear>> log,
    Map<String, List<TrackSample>> samples = const {},
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          raceLogProvider.overrideWith((ref) => log),
          trackSampleReaderProvider.overrideWith((ref) {
            return (raceId) async => samples[raceId] ?? const <TrackSample>[];
          }),
        ],
        child: MaterialApp(
          theme: foretackTheme,
          locale: const Locale('hu'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RaceLogScreen(),
        ),
      ),
    );
  }

  group('RaceLogScreen states', () {
    testWidgets('shows a spinner while the log is loading', (tester) async {
      await pumpScreen(
        tester,
        log: const AsyncValue<List<RaceLogYear>>.loading(),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(RaceLogYearBar), findsNothing);
    });

    testWidgets('draws nothing for an empty log', (tester) async {
      await pumpScreen(
        tester,
        log: const AsyncValue<List<RaceLogYear>>.data(<RaceLogYear>[]),
      );

      expect(find.byType(RaceLogYearBar), findsNothing);
      expect(find.byType(RaceLogStatsStrip), findsNothing);
      expect(find.byType(RaceLogRow), findsNothing);
    });
  });

  group('RaceLogScreen content', () {
    testWidgets('lists the months and races of the newest year', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        log: AsyncValue.data([
          logYear(
            year: 2026,
            byMonth: {
              8: ['Kekszalag'],
              5: ['Tavaszi', 'Nyitany'],
            },
          ),
          logYear(
            year: 2024,
            byMonth: {
              6: ['Regi'],
            },
          ),
        ]),
      );

      expect(find.byType(RaceLogMonthHeader), findsNWidgets(2));
      expect(find.byType(RaceLogRow), findsNWidgets(3));
      expect(find.text('Kekszalag'), findsOneWidget);
      expect(find.text('Regi'), findsNothing);
    });

    testWidgets('shows the year count in the app bar', (tester) async {
      // Ket honapra osztva, kulonben az osszesito felirat egybeesne a
      // honap-fejlecevel, es a talalat nem lenne egyertelmu.
      await pumpScreen(
        tester,
        log: AsyncValue.data([
          logYear(
            year: 2026,
            byMonth: {
              8: ['Egy'],
              5: ['Ketto', 'Harom'],
            },
          ),
        ]),
      );

      expect(find.text('3 VERSENY'), findsOneWidget);
      expect(find.text('2 VERSENY'), findsOneWidget);
      expect(find.text('1 VERSENY'), findsOneWidget);
    });

    testWidgets('defaults the year bar to the newest year', (tester) async {
      await pumpScreen(
        tester,
        log: AsyncValue.data([
          logYear(
            year: 2026,
            byMonth: {
              5: ['Uj'],
            },
          ),
          logYear(
            year: 2024,
            byMonth: {
              6: ['Regi'],
            },
          ),
        ]),
      );

      expect(find.text('2026'), findsOneWidget);
    });
  });

  group('RaceLogScreen stats strip', () {
    testWidgets('shows the elapsed time straight away', (tester) async {
      // Harom negy oras verseny = 12 ora, meg a track-osszesitok elott.
      await pumpScreen(
        tester,
        log: AsyncValue.data([
          logYear(
            year: 2026,
            byMonth: {
              5: ['Egy', 'Ketto', 'Harom'],
            },
          ),
        ]),
      );

      expect(find.byType(RaceLogStatsStrip), findsOneWidget);
      expect(find.text('12,0'), findsOneWidget);
    });

    testWidgets('holds the track cells at the gap marker until they land', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        log: AsyncValue.data([
          logYear(
            year: 2026,
            byMonth: {
              5: ['Egy'],
            },
          ),
        ]),
      );

      // Elso kepkocka: a ket track-cella meg nem szamolt.
      expect(find.text('—'), findsNWidgets(2));

      await tester.pumpAndSettle();

      // Minta nelkul a ket ertek marad hianyjel, de mar szamolt allapotban.
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('fills in the distance and the record once computed', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        log: AsyncValue.data([
          logYear(
            year: 2026,
            byMonth: {
              5: ['Egy'],
            },
          ),
        ]),
        samples: {
          'Egy': [
            RoundingSample(
              tickTime: DateTime.utc(2026),
              raceStatus: 'finished',
              twdQuality: 'live',
              sogMps: 6.2,
              latDeg: 46.90,
              lonDeg: 18.05,
            ),
            RoundingSample(
              tickTime: DateTime.utc(2026),
              raceStatus: 'finished',
              twdQuality: 'live',
              sogMps: 4,
              latDeg: 46.95,
              lonDeg: 18.05,
            ),
          ],
        },
      );

      await tester.pumpAndSettle();

      expect(find.text('12,1'), findsOneWidget);
      expect(find.text('kn'), findsOneWidget);
      expect(find.text('—'), findsNothing);
    });
  });

  group('RaceLogScreen year switching', () {
    testWidgets('swaps the list when another year is picked', (tester) async {
      await pumpScreen(
        tester,
        log: AsyncValue.data([
          logYear(
            year: 2026,
            byMonth: {
              5: ['Uj'],
            },
          ),
          logYear(
            year: 2024,
            byMonth: {
              6: ['Regi'],
            },
          ),
        ]),
      );

      expect(find.text('Uj'), findsOneWidget);
      expect(find.text('Regi'), findsNothing);

      // ACT - ev-sav megnyitasa, majd a masik ev kivalasztasa.
      await tester.tap(find.byType(RaceLogYearBar));
      await tester.pumpAndSettle();
      expect(find.byType(RaceLogYearSheet), findsOneWidget);

      await tester.tap(find.text('2024'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Regi'), findsOneWidget);
      expect(find.text('Uj'), findsNothing);
    });
  });
}
