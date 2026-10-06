import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/api/archive_api_client.dart';
import 'package:foretack_web/app/api_providers.dart';
import 'package:foretack_web/app/foretack_web_app.dart';
import 'package:foretack_web/polar/widgets/polar_table.dart';
import 'package:foretack_web/race_detail/race_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../polar/polar_fixtures.dart';
import '../support/sample_summaries.dart';

// A Statisztika-kepernyo polar-szakaszai a teljes appon at (ADR 0049
// Addendum 5): a MockClient utvonalankent valaszol, a polar-vegpontok
// valasza tesztenkent csereli.

void main() {
  final summaries = [
    telemetrySummary('lelle', start: DateTime(2026, 8, 22, 11)),
    manualSummary('m25', date: '2025-08-23'),
  ];

  final table = SeasonPolarTable(
    year: 2026,
    rows: [
      samplePolarRow('lelle', stats: samplePolarStats(), rank: 1),
      samplePolarRow('teszt', day: '2026-06-16', elapsed: null),
    ],
    rankedCount: 1,
    raceAverage: samplePolarStats(avgPct: 71.7, avgTwsMps: null),
    timeWeighted: samplePolarStats(avgPct: 67.5),
  );

  Future<void> openStatistics(
    WidgetTester tester, {
    required Future<http.Response> Function() season,
    Future<http.Response> Function() seasons = polarUnavailableResponse,
    double width = 1280,
  }) async {
    // A ListView lustan epit: a 06 szakasz a lap aljan van.
    tester.view
      ..physicalSize = Size(width, 5000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          archiveApiClientProvider.overrideWithValue(
            ArchiveApiClient(
              MockClient((request) {
                final path = request.url.path;
                if (path == racesPath) {
                  return polarJson(encodeRaceSummaries(summaries));
                }
                if (path == polarSeasonsPath) return seasons();
                if (path == polarSeasonPath(2026)) return season();
                return polarUnavailableResponse();
              }),
              baseUri: Uri.parse('http://localhost/'),
            ),
          ),
        ],
        child: const ForetackWebApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Statisztika'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the season table with its totals', (tester) async {
    // ACT
    await openStatistics(
      tester,
      season: () => polarJson(encodeSeasonPolarTable(table)),
    );

    // ASSERT
    expect(find.text('POLÁR-TELJESÍTMÉNY'), findsOneWidget);
    expect(find.text('2 verseny · időrendben'), findsOneWidget);
    expect(find.text('Verseny lelle'), findsOneWidget);
    expect(find.text('2 ó 53 p'), findsOneWidget);
    expect(find.text('83,6'), findsOneWidget);
    expect(find.text('9,5'), findsWidgets);
    expect(find.text('kevés adat'), findsOneWidget);
    expect(find.text('A futamok átlaga'), findsOneWidget);
    expect(find.text('71,7'), findsOneWidget);
    expect(find.text('Időre súlyozva'), findsOneWidget);
    expect(find.text('67,5'), findsOneWidget);
    expect(find.text('1,0 ó mért idő'), findsOneWidget);
    expect(find.textContaining('historikus felső tized'), findsOneWidget);
    expect(find.textContaining('Újraszámolás'), findsNothing);
  });

  testWidgets('says when the server is recomputing a race', (tester) async {
    // ARRANGE
    final stale = SeasonPolarTable(
      year: 2026,
      rows: [
        samplePolarRow('lelle', cacheState: PolarCacheState.missing),
      ],
      rankedCount: 0,
    );

    // ACT
    await openStatistics(
      tester,
      season: () => polarJson(encodeSeasonPolarTable(stale)),
    );

    // ASSERT
    expect(
      find.text('Újraszámolás a szerveren — a korábbi értékek látszanak.'),
      findsOneWidget,
    );
    expect(find.text('még nincs számolva'), findsOneWidget);
    expect(find.text('kevés adat'), findsNothing);
  });

  testWidgets('moves the date under the name in a narrow window', (
    tester,
  ) async {
    // ACT
    await openStatistics(
      tester,
      season: () => polarJson(encodeSeasonPolarTable(table)),
      width: 800,
    );

    // ASSERT
    expect(find.text('08.22.  2 ó 53 p'), findsOneWidget);
    expect(find.text('DÁTUM'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the heading with a sentence when there is no polar', (
    tester,
  ) async {
    // ACT
    await openStatistics(tester, season: polarUnavailableResponse);

    // ASSERT
    expect(find.text('POLÁR-TELJESÍTMÉNY'), findsOneWidget);
    expect(
      find.text(
        'Nincs polár a szerveren, ezért teljesítmény-százalék nem '
        'számolható.',
      ),
      findsOneWidget,
    );
    expect(find.text('ÚJRA'), findsNothing);
  });

  testWidgets('retries a failed load', (tester) async {
    // ARRANGE: az elso keres elbukik, a masodik sikerul
    var calls = 0;
    await openStatistics(
      tester,
      season: () {
        calls++;
        return calls == 1
            ? polarJson(encodeApiError(const InternalError()), status: 500)
            : polarJson(encodeSeasonPolarTable(table));
      },
    );
    expect(find.text('A polár-adatok nem tölthetők be.'), findsOneWidget);

    // ACT
    await tester.tap(find.text('ÚJRA'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('83,6'), findsOneWidget);
  });

  testWidgets('opens the race detail from a row', (tester) async {
    // ARRANGE
    await openStatistics(
      tester,
      season: () => polarJson(encodeSeasonPolarTable(table)),
    );

    // ACT
    await tester.tap(find.text('Verseny lelle'));
    await tester.pumpAndSettle();

    // ASSERT: a cim a polar-sor nevevel jon, a statisztika offstage
    expect(find.byType(RaceDetailScreen), findsOneWidget);
    expect(find.text('Verseny lelle'), findsOneWidget);
  });

  testWidgets('shows the seasons and switches to a year', (tester) async {
    // ARRANGE
    final seasons = [
      SeasonPolarSummary(
        year: 2025,
        raceCount: 11,
        timeWeighted: samplePolarStats(avgPct: 71, bestFivePct: null),
      ),
      SeasonPolarSummary(
        year: 2026,
        raceCount: 4,
        timeWeighted: samplePolarStats(avgPct: 67.5),
      ),
    ];
    await openStatistics(
      tester,
      season: () => polarJson(encodeSeasonPolarTable(table)),
      seasons: () => polarJson(encodeSeasonPolarSummaries(seasons)),
    );
    await tester.tap(find.text('ÖSSZES'));
    await tester.pumpAndSettle();
    expect(find.text('POLÁR ÉVENKÉNT'), findsOneWidget);
    expect(find.text('időre súlyozva · 15 verseny'), findsOneWidget);
    expect(find.text('71,0'), findsOneWidget);
    // A legujabb ev all felul.
    final years = find.descendant(
      of: find.byType(PolarTable),
      matching: find.textContaining(RegExp(r'^20\d\d$')),
    );
    expect(
      tester.widgetList<Text>(years).map((text) => text.data),
      ['2026', '2025'],
    );

    // ACT
    await tester.tap(
      find.descendant(
        of: find.byType(PolarTable),
        matching: find.text('2025'),
      ),
    );
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('AZ ÉVAD'), findsOneWidget);
    expect(find.text('POLÁR ÉVENKÉNT'), findsNothing);
  });

  testWidgets('leaves out the section of a year without polar rows', (
    tester,
  ) async {
    // ACT
    await openStatistics(
      tester,
      season: () => polarJson(
        encodeSeasonPolarTable(
          const SeasonPolarTable(year: 2026, rows: [], rankedCount: 0),
        ),
      ),
    );

    // ASSERT
    expect(find.text('POLÁR-TELJESÍTMÉNY'), findsNothing);
    expect(find.text('ÁTLAGSZÉL SZERINT'), findsOneWidget);
  });
}
