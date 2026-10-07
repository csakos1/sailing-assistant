import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/api/archive_api_client.dart';
import 'package:foretack_web/app/api_providers.dart';
import 'package:foretack_web/app/foretack_web_app.dart';
import 'package:foretack_web/season_stats/widgets/medal_table.dart';
import 'package:foretack_web/season_stats/widgets/season_overview_section.dart';
import 'package:http/testing.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../polar/polar_fixtures.dart';
import '../support/sample_summaries.dart';
import '../support/signed_in_session.dart';
import 'season_fixtures.dart';

// A teljes webes app: a naplobol nyitott Statisztika-kepernyo, valodi
// kliens-kodekkel es egy MockClient-tel a szerver helyen.

void main() {
  final summaries = [
    // osztaly 2., abszolut 14. / egytestu 3. -> abszolut bronz; 30 km,
    // 4 oras rogzites
    telemetrySummary(
      'lelle',
      start: DateTime(2026, 8, 22, 11),
      distanceMeters: 30000,
      result: const RaceResultInput(
        classPlace: FinishPlace(2),
        overallPlace: FinishPlace(14),
        monohullPlace: FinishPlace(3),
      ),
    ),
    // osztaly 1., abszolut 9.; 20 km 2 ora alatt, 5 m/s csucs, deli szel
    withStats(
      manualSummary(
        'tihany',
        date: '2026-06-14',
        result: RaceResultInput(
          classPlace: const FinishPlace(1),
          overallPlace: const FinishPlace(9),
          officialStart: DateTime.utc(2026, 6, 14, 9),
          officialFinish: DateTime.utc(2026, 6, 14, 11),
        ),
      ),
      enteredStats(
        distanceMeters: 20000,
        maxSpeedMps: 5,
        windPoint: CompassPoint.south,
      ),
    ),
    manualSummary(
      'kekszalag2024',
      date: '2024-07-25',
      result: const RaceResultInput(overallPlace: FinishPlace(1)),
    ),
  ];

  Future<void> openStatistics(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1280, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signedInSession(),
          archiveApiClientProvider.overrideWithValue(
            ArchiveApiClient(
              // A polar-szakaszok sajat teszte a season_polar_test; itt a
              // szerveren nincs polar, hogy a szamaik ne keveredjenek.
              MockClient(
                (request) => request.url.path.startsWith('/api/polar')
                    ? polarUnavailableResponse()
                    : polarJson(encodeRaceSummaries(summaries)),
              ),
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

  testWidgets('summarizes the newest year', (tester) async {
    // ACT
    await openStatistics(tester);

    // ASSERT
    for (final title in [
      'AZ ÉVAD',
      'OSZTÁLYBAN',
      'ABSZOLÚT',
      'A PÁLYÁN',
      'ÁTLAGSZÉL SZERINT',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('ÉREMTÁBLA ÉVENKÉNT'), findsNothing);
    // 2 dobogos verseny a 2-bol, 3 dobogos helyezes
    expect(find.text('100%'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SeasonOverviewSection),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    expect(find.text('Dobogón kívül: 9.'), findsOneWidget);
    // 50 km 6 ora alatt: 4,5 kn; csucs 5 m/s: 9,7 kn
    expect(find.text('4,5'), findsOneWidget);
    expect(find.text('9,7'), findsOneWidget);
    expect(find.text('Verseny lelle · 08.22.'), findsOneWidget);
    expect(find.text('Kezi tihany · 06.14.'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
  });

  testWidgets('shows the medal table for every year', (tester) async {
    // ARRANGE
    await openStatistics(tester);

    // ACT
    await tester.tap(find.text('ÖSSZES'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('ÉREMTÁBLA ÉVENKÉNT'), findsOneWidget);
    expect(find.text('Össz.'), findsOneWidget);
    expect(find.text('AZ ÉVAD'), findsNothing);
    expect(find.text('Verseny lelle · 2026.08.22.'), findsOneWidget);
  });

  testWidgets('opens a year from the medal table', (tester) async {
    // ARRANGE
    await openStatistics(tester);
    await tester.tap(find.text('ÖSSZES'));
    await tester.pumpAndSettle();

    // ACT
    await tester.tap(
      find.descendant(
        of: find.byType(MedalTable),
        matching: find.text('2024'),
      ),
    );
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('AZ ÉVAD'), findsOneWidget);
    expect(find.text('ÉREMTÁBLA ÉVENKÉNT'), findsNothing);
  });

  testWidgets('shares the chosen year with the race log', (tester) async {
    // ARRANGE
    await openStatistics(tester);

    // ACT
    await tester.tap(find.text('2024'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('Kezi kekszalag2024'), findsOneWidget);
    expect(find.text('Verseny lelle'), findsNothing);
  });
}
