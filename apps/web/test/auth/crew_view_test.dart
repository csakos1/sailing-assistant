import 'dart:convert';

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
import '../support/signed_in_session.dart';

// A legenyseg nezete (ADR 0051 Addendum 7 P7): ugyanaz az archivum,
// a modositas belepesi pontjai nelkul.

void main() {
  Future<void> pumpCrewApp(
    WidgetTester tester,
    List<RaceSummary> races,
  ) async {
    tester.view
      ..physicalSize = const Size(1280, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signedInSession(role: UserRole.crew),
          archiveApiClientProvider.overrideWithValue(
            ArchiveApiClient(
              MockClient((request) async {
                final path = request.url.path;
                if (path == racesPath) {
                  return http.Response(
                    jsonEncode(encodeRaceSummaries(races)),
                    200,
                  );
                }
                if (races.isNotEmpty && path == racePolarPath(races[0].id)) {
                  return polarUnavailableResponse();
                }
                return http.Response(
                  jsonEncode(encodeRaceDetail(RaceDetail(summary: races[0]))),
                  200,
                );
              }),
              baseUri: Uri.parse('http://localhost/'),
            ),
          ),
        ],
        child: const ForetackWebApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the log keeps the views and hides every edit control', (
    tester,
  ) async {
    // ACT
    await pumpCrewApp(tester, [manualSummary('lelle', date: '2026-08-22')]);

    // ASSERT
    expect(find.text('Gergo'), findsOneWidget);
    expect(find.byTooltip('Statisztika'), findsOneWidget);
    expect(find.text('Új verseny'), findsNothing);
    expect(find.text('Feltöltés'), findsNothing);
    expect(find.byTooltip('Export'), findsNothing);
  });

  testWidgets('the menu names the crew role', (tester) async {
    // ARRANGE
    await pumpCrewApp(tester, [manualSummary('lelle', date: '2026-08-22')]);

    // ACT
    await tester.tap(find.text('Gergo'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('LEGÉNYSÉG'), findsOneWidget);
  });

  testWidgets('the detail has no pencil and no editor link', (tester) async {
    // ARRANGE
    await pumpCrewApp(tester, [manualSummary('lelle', date: '2026-08-22')]);

    // ACT
    await tester.tap(find.byType(RaceLogRow));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eredmény még nincs rögzítve.'));
    await tester.pumpAndSettle();

    // ASSERT: a sor csak tajekoztat, szerkesztot nem nyit
    expect(find.byTooltip('Szerkesztés'), findsNothing);
    expect(find.text('Eredmény még nincs rögzítve.'), findsOneWidget);
    expect(find.text('Verseny törlése'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('an empty archive does not ask the crew to upload', (
    tester,
  ) async {
    // ACT
    await pumpCrewApp(tester, const []);

    // ASSERT
    expect(find.text('Még nincs verseny az archívumban.'), findsOneWidget);
  });
}
