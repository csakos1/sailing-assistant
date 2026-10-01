import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/api/archive_api_client.dart';
import 'package:foretack_web/app/api_providers.dart';
import 'package:foretack_web/app/foretack_web_app.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../support/sample_summaries.dart';

// A naplobol nyitott reszletezo a teljes appon at, MockClient-tel. A
// telemetrias verseny trackje szandekosan ures: igy a TrackMap nem kezd
// csempeket tolteni a tesztben, csak az ures allapotot rajzolja.

void main() {
  const tihany = Mark(
    sequence: 1,
    name: 'Tihany',
    position: Coordinate(latitude: 46.9186, longitude: 17.9092),
  );

  RaceDetail telemetryDetail({RaceResultInput? result}) {
    final start = DateTime(2026, 7, 26, 11);
    final started = Race.create(
      id: 'horvath',
      name: 'Horvath',
      marks: const [tihany],
    ).start(at: start);
    final race = started.roundCurrentMark(
      at: start.add(const Duration(hours: 2)),
    );
    return RaceDetail(
      summary: telemetrySummary(
        'horvath',
        start: start,
        hours: 2,
        distanceMeters: 22600,
        maxSpeedMps: 4,
        result: result,
      ),
      telemetry: TelemetryRaceData(
        race: race,
        trackPoints: const [],
        roundings: const [],
      ),
    );
  }

  Future<http.Response> json(Object? body, {int status = 200}) async =>
      http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Future<void> openDetail(
    WidgetTester tester, {
    required RaceSummary listed,
    required Future<http.Response> Function() detail,
  }) async {
    // A ListView lustan epit: a 800x600-as alap nezetben a 560 magas
    // terkep-kartya alatti blokkok (bojak, osszefoglalo) meg sem epulnek.
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
                (request) => request.url.path == racesPath
                    ? json(encodeRaceSummaries([listed]))
                    : detail(),
              ),
              baseUri: Uri.parse('http://localhost/'),
            ),
          ),
        ],
        child: const ForetackWebApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(RaceLogRow));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a telemetry race with strips, result and marks', (
    tester,
  ) async {
    // ARRANGE
    final detail = telemetryDetail(
      result: const RaceResultInput(
        overallPlace: FinishPlace(3),
        overallFleetSize: 24,
        classPlace: Dnf(),
        ysNumberHundredths: 7590,
        summary: 'Gyenge szel.',
      ),
    );

    // ACT
    await openDetail(
      tester,
      listed: detail.summary,
      detail: () => json(encodeRaceDetail(detail)),
    );

    // ASSERT
    expect(find.byType(DetailStatusStrip), findsOneWidget);
    expect(find.byType(TrackStatsRow), findsOneWidget);
    expect(find.text('SZÉLIRÁNY'), findsOneWidget);
    expect(find.textContaining('Közelítő értékek'), findsOneWidget);
    expect(find.text('EREDMÉNY'), findsOneWidget);
    expect(find.text('/ 24'), findsOneWidget);
    expect(find.text('DNF'), findsOneWidget);
    expect(find.text('75,90'), findsOneWidget);
    expect(find.byType(DetailMarkRow), findsOneWidget);
    expect(find.text('Gyenge szel.'), findsOneWidget);
  });

  testWidgets('hides the approximate note with official times', (tester) async {
    // ARRANGE: a sablon hivatalos ablakot kap
    final base = telemetryDetail();
    final official = TimeWindow(
      start: DateTime(2026, 7, 26, 11, 10),
      end: DateTime(2026, 7, 26, 12, 50),
    );
    final detail = RaceDetail(
      summary: RaceSummary(
        id: base.summary.id,
        name: base.summary.name,
        origin: base.summary.origin,
        stats: RaceStats(window: OfficialWindow(official)),
        result: RaceResult(
          raceId: 'horvath',
          content: RaceResultInput(
            officialStart: official.start,
            officialFinish: official.end,
          ),
          updatedAt: DateTime.utc(2026, 10),
        ),
      ),
      telemetry: base.telemetry,
    );

    // ACT
    await openDetail(
      tester,
      listed: detail.summary,
      detail: () => json(encodeRaceDetail(detail)),
    );

    // ASSERT
    expect(find.textContaining('Közelítő értékek'), findsNothing);
    expect(find.text('MENETIDŐ'), findsOneWidget);
    expect(find.text('01:40:00'), findsOneWidget);
  });

  testWidgets('shows a manual race without map and marks', (tester) async {
    // ARRANGE
    final summary = manualSummary('m1', date: '2025-08-23');
    final detail = RaceDetail(summary: summary);

    // ACT
    await openDetail(
      tester,
      listed: summary,
      detail: () => json(encodeRaceDetail(detail)),
    );

    // ASSERT
    expect(find.text('KÉZI RÖGZÍTÉS'), findsOneWidget);
    expect(find.text('Eredmény még nincs rögzítve.'), findsOneWidget);
    expect(find.byType(TrackMap), findsNothing);
    expect(find.text('BÓJÁK'), findsNothing);
  });

  testWidgets('explains a race that is gone, without a retry', (tester) async {
    // ARRANGE
    final summary = manualSummary('m1', date: '2025-08-23');

    // ACT
    await openDetail(
      tester,
      listed: summary,
      detail: () => json(encodeApiError(const RaceNotFound('m1')), status: 404),
    );

    // ASSERT
    expect(find.text('Ez a verseny már nincs az archívumban.'), findsOneWidget);
    expect(find.text('ÚJRA'), findsNothing);
  });

  testWidgets('goes back to the log', (tester) async {
    // ARRANGE
    final summary = manualSummary('m1', date: '2025-08-23');
    await openDetail(
      tester,
      listed: summary,
      detail: () => json(encodeRaceDetail(RaceDetail(summary: summary))),
    );

    // ACT
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.byType(RaceLogRow), findsOneWidget);
  });
}
