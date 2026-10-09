import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/api/archive_api_client.dart';
import 'package:foretack_web/app/api_providers.dart';
import 'package:foretack_web/app/foretack_web_app.dart';
import 'package:foretack_web/race_edit/widgets/placing_pair_row.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

import '../support/sample_summaries.dart';
import '../support/signed_in_session.dart';

// Az eredmeny-szerkeszto a teljes appon at: naplo -> reszletezo -> ceruza.
// A szerver egy MockClient, amely a mentett eredmenyt a kovetkezo
// reszletezo-valaszba is beteszi.

void main() {
  late RaceDetail detail;
  late List<http.Request> writes;

  RaceDetail telemetryDetail({RaceResultInput? result}) {
    final start = DateTime(2026, 7, 26, 11);
    final started = Race.create(
      id: 'horvath',
      name: 'Horvath',
      marks: const [
        Mark(
          sequence: 1,
          name: 'Tihany',
          position: Coordinate(latitude: 46.9186, longitude: 17.9092),
        ),
      ],
    ).start(at: start);
    final race = started.roundCurrentMark(
      at: start.add(const Duration(hours: 2)),
    );
    return RaceDetail(
      summary: telemetrySummary(
        'horvath',
        start: start,
        hours: 2,
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

  Future<http.Response> answer(http.Request request) {
    if (request.method == 'PUT') {
      writes.add(request);
      final input = switch (decodeRaceResultInput(jsonDecode(request.body))) {
        Ok(:final value) => value,
        Err(:final error) => throw StateError('rossz torzs: $error'),
      };
      detail = telemetryDetail(result: input);
      return json(
        encodeRaceResult(
          RaceResult(
            raceId: 'horvath',
            content: input,
            updatedAt: DateTime.utc(2026, 10),
          ),
        ),
      );
    }
    return request.url.path == racesPath
        ? json(encodeRaceSummaries([detail.summary]))
        : json(encodeRaceDetail(detail));
  }

  Future<void> openEditor(WidgetTester tester) async {
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
              MockClient(answer),
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
    await tester.tap(find.byTooltip('Szerkesztés'));
    await tester.pumpAndSettle();
  }

  Finder pairField(String rowLabel, int index) => find
      .descendant(
        of: find.widgetWithText(PlacingPairRow, rowLabel),
        matching: find.byType(TextField),
      )
      .at(index);

  setUp(() {
    detail = telemetryDetail();
    writes = [];
  });

  testWidgets('saves a placing and returns to the detail with a snack bar', (
    tester,
  ) async {
    // ARRANGE
    await openEditor(tester);
    expect(find.text('Eredmény szerkesztése'), findsOneWidget);

    // ACT
    await tester.enterText(pairField('Abszolút', 0), '3');
    await tester.enterText(pairField('Abszolút', 1), '24');
    await tester.tap(find.text('Mentés'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(writes, hasLength(1));
    expect(writes.single.url.path, raceResultPath('horvath'));
    final sent = jsonDecode(writes.single.body) as Map<String, Object?>;
    expect(sent['overallPlace'], 3);
    expect(sent['overallFleetSize'], 24);
    expect(find.text('Eredmény szerkesztése'), findsNothing);
    expect(find.text('Eredmény mentve'), findsOneWidget);
    expect(find.text('ABSZOLÚT'), findsOneWidget);
  });

  testWidgets('shows a rule violation under the pair and does not save', (
    tester,
  ) async {
    // ARRANGE
    await openEditor(tester);

    // ACT
    await tester.enterText(pairField('Abszolút', 0), '25');
    await tester.enterText(pairField('Abszolút', 1), '24');
    await tester.tap(find.text('Mentés'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(writes, isEmpty);
    expect(
      find.text('A helyezés nem lehet nagyobb a mezőnynél (24).'),
      findsOneWidget,
    );
  });

  testWidgets('asks before dropping unsaved changes', (tester) async {
    // ARRANGE
    await openEditor(tester);
    await tester.enterText(pairField('Osztály', 0), '1');

    // ACT: elso kiserlet -> Folytatom
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Elveted a változtatásokat?'), findsOneWidget);
    await tester.tap(find.text('Folytatom'));
    await tester.pumpAndSettle();

    // ASSERT: marad a szerkesztoben
    expect(find.text('Eredmény szerkesztése'), findsOneWidget);

    // ACT: masodik kiserlet -> Elvetes
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elvetés'));
    await tester.pumpAndSettle();

    // ASSERT: vissza a reszletezore, mentes nelkul
    expect(find.text('Eredmény szerkesztése'), findsNothing);
    expect(writes, isEmpty);
  });

  testWidgets('leaves at once when nothing changed', (tester) async {
    // ARRANGE
    await openEditor(tester);

    // ACT
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('Elveted a változtatásokat?'), findsNothing);
    expect(find.text('Eredmény szerkesztése'), findsNothing);
  });
}
