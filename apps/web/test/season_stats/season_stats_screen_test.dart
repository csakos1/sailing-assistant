import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/api/archive_api_client.dart';
import 'package:foretack_web/app/api_providers.dart';
import 'package:foretack_web/app/foretack_web_app.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../support/sample_summaries.dart';
import 'season_fixtures.dart';

// A teljes webes app: a naplobol nyitott Statisztika-kepernyo, valodi
// kliens-kodekkel es egy MockClient-tel a szerver helyen.

void main() {
  final summaries = [
    // 4 oras rogzites, 30 km, hivatalos idok nelkul (kozelito)
    telemetrySummary(
      'lelle',
      start: DateTime(2026, 8, 22, 11),
      distanceMeters: 30000,
      result: const RaceResultInput(
        classPlace: FinishPlace(2),
        overallPlace: FinishPlace(14),
      ),
    ),
    // 2 oras hivatalos ido, 20 km
    manualSummary(
      'tihany',
      date: '2026-06-14',
      distanceMeters: 20000,
      result: officialTimes(
        DateTime.utc(2026, 6, 14, 9),
        const Duration(hours: 2),
      ),
    ),
    manualSummary('kekszalag2024', date: '2024-07-25'),
  ];

  Future<void> openStatistics(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1280, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          archiveApiClientProvider.overrideWithValue(
            ArchiveApiClient(
              MockClient(
                (request) async => http.Response.bytes(
                  utf8.encode(jsonEncode(encodeRaceSummaries(summaries))),
                  200,
                  headers: {'content-type': 'application/json; charset=utf-8'},
                ),
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
    expect(find.text('HELYEZÉSEK'), findsOneWidget);
    expect(find.text('1 telemetriás és 1 kézi verseny.'), findsOneWidget);
    expect(find.textContaining('Egyes számok közelítők'), findsOneWidget);
    expect(find.textContaining('nincs hivatalos ideje'), findsNothing);
    // osztaly es abszolut 1/2, egytestu 0/2
    expect(find.text('1/2'), findsNWidgets(2));
    expect(find.text('0/2'), findsOneWidget);
    // 50 km 6 ora alatt: 4,5 kn
    expect(find.text('4,5'), findsOneWidget);
    expect(find.text('2 versenyen nincs szélmérés.'), findsOneWidget);
    expect(find.text('ÉVEK'), findsNothing);
  });

  testWidgets('compares the years for every year', (tester) async {
    // ARRANGE
    await openStatistics(tester);

    // ACT
    await tester.tap(find.text('ÖSSZES'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('ÉVEK'), findsOneWidget);
    expect(find.text('2024–2026'), findsOneWidget);
    expect(find.textContaining('1 kézi versenynek'), findsOneWidget);
    expect(find.text('1/3'), findsNWidgets(2));
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
