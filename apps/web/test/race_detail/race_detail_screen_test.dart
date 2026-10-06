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

import '../polar/polar_fixtures.dart';
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
    Future<http.Response> Function() polar = polarUnavailableResponse,
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
              MockClient((request) {
                final path = request.url.path;
                if (path == racesPath) {
                  return json(encodeRaceSummaries([listed]));
                }
                return path == racePolarPath(listed.id) ? polar() : detail();
              }),
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

  RaceSummary trackedManualSummary() {
    final start = DateTime.utc(2023, 7, 6, 8);
    final finish = start.add(const Duration(hours: 20));
    return RaceSummary(
      id: 'm2',
      name: 'Kezi m2',
      origin: ManualOrigin(CalendarDate.tryParse('2023-07-06')!),
      stats: RaceStats(
        window: OfficialWindow(TimeWindow(start: start, end: finish)),
        track: const TrackStats(distanceMeters: 152600, avgSpeedMps: 2.1),
      ),
      result: RaceResult(
        raceId: 'm2',
        content: RaceResultInput(officialStart: start, officialFinish: finish),
        updatedAt: DateTime.utc(2026, 10),
      ),
    );
  }

  testWidgets('shows the old track of a manual race without marks', (
    tester,
  ) async {
    // ARRANGE: ures track, hogy a TrackMap ne toltson csempet (ADR 0050 D7)
    final summary = trackedManualSummary();
    final detail = RaceDetail(summary: summary, legacyTrack: const []);

    // ACT
    await openDetail(
      tester,
      listed: summary,
      detail: () => json(encodeRaceDetail(detail)),
    );

    // ASSERT
    expect(find.byType(TrackMap), findsOneWidget);
    expect(find.text('BÓJÁK'), findsNothing);
    expect(find.textContaining('Közelítő értékek'), findsNothing);
  });

  testWidgets('locks the computed stats in the editor of a tracked race', (
    tester,
  ) async {
    // ARRANGE
    final summary = trackedManualSummary();
    await openDetail(
      tester,
      listed: summary,
      detail: () => json(encodeRaceDetail(RaceDetail(summary: summary))),
    );

    // ACT
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    // ASSERT: tav, max. sebesseg, atlagos es max. szel (F3)
    final disabled = tester
        .widgetList<TextField>(find.byType(TextField))
        .where((field) => !(field.enabled ?? true));
    expect(disabled, hasLength(4));
    expect(find.textContaining('régi trackből számolódik'), findsOneWidget);
    expect(find.text('152,6'), findsOneWidget);
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

  group('polar block', () {
    final detail = telemetryDetail();

    Future<void> openWithPolar(WidgetTester tester, RacePolarRow row) =>
        openDetail(
          tester,
          listed: detail.summary,
          detail: () => json(encodeRaceDetail(detail)),
          polar: () => json(
            encodeRacePolarDetail(
              RacePolarDetail(row: row, rankedCount: 15),
            ),
          ),
        );

    testWidgets('shows the season rank and the metrics', (tester) async {
      // ACT
      await openWithPolar(
        tester,
        samplePolarRow('horvath', stats: samplePolarStats(), rank: 4),
      );

      // ASSERT
      expect(find.text('POLÁR'), findsOneWidget);
      expect(find.text('4.'), findsOneWidget);
      expect(find.text('/ 15'), findsOneWidget);
      expect(find.text('83,6'), findsOneWidget);
      expect(find.text('85,2'), findsOneWidget);
      expect(find.text('116,7'), findsOneWidget);
      expect(find.text('40,1'), findsOneWidget);
      expect(find.text('14,5'), findsOneWidget);
      expect(find.text('≈ KÖZELÍTŐ'), findsNothing);
      // A polar az eredmeny folott all (W1).
      expect(
        tester.getTopLeft(find.text('POLÁR')).dy,
        lessThan(tester.getTopLeft(find.text('EREDMÉNY')).dy),
      );
    });

    testWidgets('marks an approximate race in the header', (tester) async {
      // ACT
      await openWithPolar(
        tester,
        samplePolarRow(
          'horvath',
          stats: samplePolarStats(bestFivePct: null),
          rank: 6,
          isApproximate: true,
        ),
      );

      // ASSERT
      expect(find.text('≈ KÖZELÍTŐ'), findsOneWidget);
      expect(find.text('LEGJOBB 5 MP'), findsOneWidget);
      expect(find.text('116,7'), findsNothing);
    });

    testWidgets('shows dashes for a race with few data', (tester) async {
      // ACT
      await openWithPolar(tester, samplePolarRow('horvath'));

      // ASSERT
      expect(find.text('KEVÉS ADAT'), findsOneWidget);
      expect(find.text('/ 15'), findsNothing);
      expect(find.text('83,6'), findsNothing);
      expect(find.textContaining('Újraszámolás'), findsNothing);
    });

    testWidgets('says when the server is recomputing the race', (
      tester,
    ) async {
      // ACT
      await openWithPolar(
        tester,
        samplePolarRow(
          'horvath',
          stats: samplePolarStats(),
          rank: 4,
          cacheState: PolarCacheState.stale,
        ),
      );

      // ASSERT
      expect(
        find.text('Újraszámolás a szerveren — a korábbi értékek látszanak.'),
        findsOneWidget,
      );
      expect(find.text('83,6'), findsOneWidget);
    });

    testWidgets('leaves the block out when there is no polar', (
      tester,
    ) async {
      // ACT
      await openDetail(
        tester,
        listed: detail.summary,
        detail: () => json(encodeRaceDetail(detail)),
      );

      // ASSERT
      expect(find.text('POLÁR'), findsNothing);
      expect(find.text('EREDMÉNY'), findsOneWidget);
    });
  });
}
