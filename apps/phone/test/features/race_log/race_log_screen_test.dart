import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/race_log/race_log_screen.dart';
import 'package:phone/features/race_log/widgets/race_log_empty.dart';
import 'package:phone/features/race_log/widgets/race_log_loading_list.dart';
import 'package:phone/features/race_log/widgets/race_log_year_band.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/race_log_provider.dart';
import 'package:phone/providers/race_track_stats_provider.dart';
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
    TrackSampleReader? readSamples,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          raceLogProvider.overrideWith((ref) => log),
          trackSampleReaderProvider.overrideWith((ref) {
            return readSamples ??
                (raceId) async => samples[raceId] ?? const <TrackSample>[];
          }),
          // A stat-csik a gyorsitotarat is olvassa; ures cache mellett a
          // minta-olvasohoz jut, iras utan viszont nem all fel valos DB.
          raceTrackStatsReaderProvider.overrideWith(
            (ref) =>
                (raceId) async => null,
          ),
          raceTrackStatsWriterProvider.overrideWith((ref) => _ignoreWrite),
        ],
        child: MaterialApp(
          theme: foretackTheme,
          locale: const Locale('hu'),
          localizationsDelegates: phoneLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RaceLogScreen(),
        ),
      ),
    );
  }

  group('RaceLogScreen states', () {
    testWidgets('shows the skeleton while the log is loading', (tester) async {
      await pumpScreen(
        tester,
        log: const AsyncValue<List<RaceLogYear>>.loading(),
      );

      // Makett 35f: az evsav a helyen hianyjelekkel, a lista helyen vazak,
      // korre forgo spinner nelkul.
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RaceLogScreen)),
      )!;
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(RaceLogLoadingList), findsOneWidget);
      expect(find.text(l10n.logLoadingCaps), findsOneWidget);
      expect(find.text(l10n.logRaceCountPendingCaps), findsOneWidget);
      expect(find.text('––––'), findsOneWidget);
      expect(find.text('––,–'), findsNWidgets(3));
      expect(find.text('ó'), findsOneWidget);
      expect(find.byType(RaceLogRow), findsNothing);
    });

    testWidgets('says so for an empty log', (tester) async {
      await pumpScreen(
        tester,
        log: const AsyncValue<List<RaceLogYear>>.data(<RaceLogYear>[]),
      );

      // Fulkent ures naploval is elerheto (ADR 0056 D2).
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RaceLogScreen)),
      )!;
      expect(find.byType(RaceLogEmpty), findsOneWidget);
      expect(find.text(l10n.logEmptyTitle), findsOneWidget);
      expect(find.byType(RaceLogYearBand), findsNothing);
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

    testWidgets('shows the year count in the year band', (tester) async {
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

      expect(
        find.descendant(
          of: find.byType(RaceLogYearBand),
          matching: find.text('3 VERSENY'),
        ),
        findsOneWidget,
      );
      expect(find.text('2 VERSENY'), findsOneWidget);
      expect(find.text('1 VERSENY'), findsOneWidget);
    });

    testWidgets('defaults the year band to the newest year', (tester) async {
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

      // A kivalasztott ev nagyban, a tobbi kicsiben, a helyen.
      final selectedSize = tester
          .widget<DefaultTextStyle>(
            find
                .ancestor(
                  of: find.text('2026'),
                  matching: find.byType(DefaultTextStyle),
                )
                .first,
          )
          .style
          .fontSize;
      final otherSize = tester
          .widget<DefaultTextStyle>(
            find
                .ancestor(
                  of: find.text('2024'),
                  matching: find.byType(DefaultTextStyle),
                )
                .first,
          )
          .style
          .fontSize;
      expect(selectedSize, 38);
      expect(otherSize, 14);
      expect(
        tester.getTopLeft(find.text('2026')).dx,
        lessThan(tester.getTopLeft(find.text('2024')).dx),
      );
    });

    testWidgets('uses the tab header with a hairline', (tester) async {
      await pumpScreen(
        tester,
        log: AsyncValue.data([
          logYear(
            year: 2026,
            byMonth: {
              5: ['Uj'],
            },
          ),
        ]),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.toolbarHeight, 64);
      expect(appBar.shape, isA<Border>());
      final title = tester.widget<Text>(find.text('Versenynapló'));
      expect(title.style?.fontSize, tabTitleStyle.fontSize);
      expect(find.byType(BackButton), findsNothing);
    });
  });

  group('RaceLogScreen year band stats', () {
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

      expect(
        find.descendant(
          of: find.byType(RaceLogYearBand),
          matching: find.text('12,0'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('holds the track cells pending until they land', (
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

      // Elso kepkocka: a ket track-cella meg szamolodik, a sav alja fut.
      expect(find.text('––,–'), findsNWidgets(2));
      // A hianyjel mellett a mertekegyseg mar a helyen all (makett 35f).
      expect(find.text('km'), findsOneWidget);
      expect(find.text('kn'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNothing);

      // Minta nelkul a ket ertek marad hianyjel, de mar szamolt allapotban.
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('a year switch holds the stats until the new year lands', (
      tester,
    ) async {
      // ARRANGE - a 2025-os verseny mintai meg nem erkeztek meg.
      final pendingSamples = Completer<List<TrackSample>>();
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
            year: 2025,
            byMonth: {
              5: ['Regi'],
            },
          ),
        ]),
        readSamples: (raceId) => raceId == 'Regi'
            ? pendingSamples.future
            : Future.value(const <TrackSample>[]),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);

      // ACT
      await tester.tap(find.text('2025'));
      await tester.pump();

      // ASSERT - nem a 2026-os ertek all a 2025-os ev alatt (D38).
      expect(find.text('––,–'), findsNWidgets(2));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // ACT - megerkeznek a mintak.
      pendingSamples.complete(const <TrackSample>[]);
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.byType(LinearProgressIndicator), findsNothing);
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
    testWidgets('swaps the list when another year is tapped', (tester) async {
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

      // ACT - az evsorban a masik ev (mint a weben, lap nelkul).
      await tester.tap(find.text('2024'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Regi'), findsOneWidget);
      expect(find.text('Uj'), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('gives every year a tap target of at least 48 dp', (
      tester,
    ) async {
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
      await tester.pumpAndSettle();

      final target = find.ancestor(
        of: find.text('2024'),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
    });

    testWidgets('scrolls the years sideways when they do not fit', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(300, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpScreen(
        tester,
        log: AsyncValue.data([
          for (var year = 2026; year >= 2015; year--)
            logYear(
              year: year,
              byMonth: {
                5: ['R$year'],
              },
            ),
        ]),
      );
      await tester.pumpAndSettle();

      // ASSERT - nincs tulcsordulas, es az evsor oldalra gorgetheto.
      expect(tester.takeException(), isNull);
      final scrollable = find.descendant(
        of: find.byType(RaceLogYearBand),
        matching: find.byType(Scrollable),
      );
      expect(
        tester.widget<Scrollable>(scrollable).axisDirection,
        AxisDirection.right,
      );

      await tester.drag(scrollable, const Offset(-2000, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2015'));
      await tester.pumpAndSettle();
      expect(find.text('R2015'), findsOneWidget);
    });
  });
}

/// A gyorsitotar-iro semmit nem csinalo dublore a teszthez.
Future<void> _ignoreWrite(
  String raceId,
  TrackStats stats, {
  required int sampleCount,
  required DateTime computedAt,
}) async {}
