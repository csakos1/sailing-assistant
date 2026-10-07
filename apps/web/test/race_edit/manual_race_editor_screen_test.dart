import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/api/archive_api_client.dart';
import 'package:foretack_web/app/api_providers.dart';
import 'package:foretack_web/app/foretack_web_app.dart';
import 'package:foretack_web/race_edit/widgets/race_identity_section.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../support/sample_summaries.dart';
import '../support/signed_in_session.dart';

// A kezi verseny szerkesztoje a teljes appon at: letrehozas a naplobol,
// torles a reszletezobol. A szerver egy MockClient, amely a kereseket
// rogziti, es a letrehozott versenyt a kovetkezo listaba is beteszi.

void main() {
  late List<RaceSummary> listed;
  late List<http.Request> writes;

  Future<http.Response> json(Object? body, {int status = 200}) async =>
      http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Future<http.Response> answer(http.Request request) {
    final path = request.url.path;
    switch (request.method) {
      case 'POST':
        writes.add(request);
        final created = manualSummary('m-new', date: '2025-10-19');
        listed = [...listed, created];
        return json(encodeRaceSummary(created), status: 201);
      case 'DELETE':
        writes.add(request);
        listed = [];
        return Future.value(http.Response('', 204));
    }
    if (path == racesPath) return json(encodeRaceSummaries(listed));
    final matching = listed.where((race) => racePath(race.id) == path);
    if (matching.isEmpty) {
      return json(encodeApiError(const RaceNotFound('?')), status: 404);
    }
    return json(encodeRaceDetail(RaceDetail(summary: matching.first)));
  }

  Future<void> pumpApp(WidgetTester tester) async {
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
  }

  Finder identityField(int index) => find
      .descendant(
        of: find.byType(RaceIdentitySection),
        matching: find.byType(TextField),
      )
      .at(index);

  setUp(() {
    listed = [];
    writes = [];
  });

  testWidgets('creates a race and opens its detail with a snack bar', (
    tester,
  ) async {
    // ARRANGE
    await pumpApp(tester);
    await tester.tap(find.text('Új verseny'));
    await tester.pumpAndSettle();
    expect(find.byType(RaceIdentitySection), findsOneWidget);

    // ACT
    await tester.enterText(identityField(0), 'Siofoki Evadzaro');
    await tester.enterText(identityField(1), '20251019');
    await tester.tap(find.text('Mentés'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(writes, hasLength(1));
    expect(writes.single.url.path, manualRacesPath);
    final sent = jsonDecode(writes.single.body) as Map<String, Object?>;
    final race = sent['race']! as Map<String, Object?>;
    expect(race['name'], 'Siofoki Evadzaro');
    expect(race['date'], '2025-10-19');
    expect(find.byType(RaceIdentitySection), findsNothing);
    expect(find.text('KÉZI RÖGZÍTÉS'), findsOneWidget);
    expect(find.text('Verseny létrehozva'), findsOneWidget);
  });

  testWidgets('marks the missing name and date and does not save', (
    tester,
  ) async {
    // ARRANGE
    await pumpApp(tester);
    await tester.tap(find.text('Új verseny'));
    await tester.pumpAndSettle();

    // ACT
    await tester.tap(find.text('Mentés'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(writes, isEmpty);
    expect(find.text('Kötelező mező.'), findsNWidgets(2));
  });

  testWidgets('deletes a manual race after confirming, back to the log', (
    tester,
  ) async {
    // ARRANGE
    listed = [manualSummary('m1', date: '2025-08-23')];
    await pumpApp(tester);
    await tester.tap(find.byType(RaceLogRow));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Szerkesztés'));
    await tester.pumpAndSettle();

    // ACT
    await tester.tap(find.byTooltip('Verseny törlése'));
    await tester.pumpAndSettle();
    expect(find.text('Törlöd a versenyt?'), findsOneWidget);
    await tester.tap(find.text('Törlés'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(writes.single.method, 'DELETE');
    expect(writes.single.url.path, manualRacePath('m1'));
    expect(find.byType(RaceIdentitySection), findsNothing);
    expect(find.text('Versenynapló'), findsOneWidget);
    expect(find.text('Verseny törölve'), findsOneWidget);
  });

  testWidgets('keeps the race when the delete is cancelled', (tester) async {
    // ARRANGE
    listed = [manualSummary('m1', date: '2025-08-23')];
    await pumpApp(tester);
    await tester.tap(find.byType(RaceLogRow));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Szerkesztés'));
    await tester.pumpAndSettle();

    // ACT
    await tester.tap(find.byTooltip('Verseny törlése'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mégse'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(writes, isEmpty);
    expect(find.byType(RaceIdentitySection), findsOneWidget);
  });
}
