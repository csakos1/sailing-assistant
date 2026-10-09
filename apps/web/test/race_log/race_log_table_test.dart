import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/api/archive_api_client.dart';
import 'package:foretack_web/app/api_providers.dart';
import 'package:foretack_web/app/foretack_web_app.dart';
import 'package:foretack_web/race_detail/race_detail_screen.dart';
import 'package:foretack_web/race_log/table/race_table.dart';
import 'package:foretack_web/race_log/widgets/log_view_toggle.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../support/sample_summaries.dart';
import '../support/signed_in_session.dart';

// A teljes webes app a Tablazat nezettel, MockClient-tel a szerver helyen.
// A nezet 3200 px szeles: a teszt-betu minden jele egy em szeles, igy a
// tartalomhoz mert oszlopok (L4) szelesebbek a valodinal, es mind a 16
// oszlopnak gorgetes nelkul latszania kell.

void main() {
  final summaries = [
    telemetrySummary(
      'lelle',
      start: DateTime(2026, 8, 22, 11),
      distanceMeters: 9800,
    ),
    telemetrySummary(
      'kekszalag',
      start: DateTime(2026, 7, 30, 9),
      distanceMeters: 172300,
    ),
    manualSummary(
      'evadzaro',
      date: '2025-10-19',
      distanceMeters: 30900,
      result: const RaceResultInput(
        overallPlace: FinishPlace(3),
        overallFleetSize: 24,
      ),
    ),
  ];

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(3200, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signedInSession(),
          archiveApiClientProvider.overrideWithValue(
            ArchiveApiClient(
              MockClient((request) async {
                // A reszletezo kereset nem szolgaljuk ki: a teszt csak a
                // navigaciot nezi.
                if (!request.url.path.endsWith('/api/races')) {
                  return http.Response('', 404);
                }
                return http.Response.bytes(
                  utf8.encode(jsonEncode(encodeRaceSummaries(summaries))),
                  200,
                  headers: {'content-type': 'application/json; charset=utf-8'},
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

  Future<void> showTable(WidgetTester tester) async {
    await tester.tap(find.text('Táblázat'));
    await tester.pumpAndSettle();
  }

  // A nevek fentrol lefele, a sorok fuggoleges helye szerint.
  List<String> namesTopDown(WidgetTester tester, List<String> names) =>
      [...names]..sort(
        (a, b) => tester
            .getTopLeft(find.text(a))
            .dy
            .compareTo(tester.getTopLeft(find.text(b)).dy),
      );

  testWidgets('opens on the list and switches to the table', (tester) async {
    // ARRANGE
    await pumpApp(tester);
    expect(find.byType(RaceLogRow), findsWidgets);
    expect(find.byType(RaceTable), findsNothing);

    // ACT
    await showTable(tester);

    // ASSERT
    expect(find.byType(RaceTable), findsOneWidget);
    expect(find.byType(RaceLogRow), findsNothing);
    expect(find.text('MAX SZÉL'), findsOneWidget);
    expect(find.text('SEBESSÉG ÉS SZÉL'), findsOneWidget);
    // A mertekegyseg a fejlec masodik soraban all (L5); a stat-csik is ir
    // "km"-t, ezert a kereses a tablazatra szukul.
    Finder inTable(String text) => find.descendant(
      of: find.byType(RaceTable),
      matching: find.text(text),
    );
    expect(inTable('km'), findsOneWidget);
    expect(inTable('kn'), findsNWidgets(4));
    expect(inTable('ó:p'), findsNWidgets(2));
    expect(find.text('Verseny lelle'), findsOneWidget);
    // A telemetrias verseny hivatalos idok nelkul kozelito (G6).
    expect(find.text('~9,8'), findsOneWidget);
  });

  testWidgets('switches with the arrow keys from the toggle', (tester) async {
    // ARRANGE
    await pumpApp(tester);

    // ACT: fokusz a valtora (az evsavban all, az AppBar gombjai utan,
    // ADR 0048 Addendum 8 Q2), majd jobbra nyil.
    Focus.of(
      tester.element(
        find
            .descendant(
              of: find.byType(LogViewToggle),
              matching: find.byType(Container),
            )
            .first,
      ),
    ).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.byType(RaceTable), findsOneWidget);
  });

  testWidgets('shows every year with year rows when all years are chosen', (
    tester,
  ) async {
    // ARRANGE
    await pumpApp(tester);
    await tester.tap(find.text('ÖSSZES'));
    await tester.pumpAndSettle();

    // ACT
    await showTable(tester);

    // ASSERT: az uj elol, az 2025-os manualis sor KEZI cimkevel.
    expect(find.text('Kezi evadzaro'), findsOneWidget);
    expect(find.text('KÉZI'), findsOneWidget);
    expect(find.text('/24'), findsOneWidget);
    expect(
      namesTopDown(tester, [
        'Kezi evadzaro',
        'Verseny kekszalag',
        'Verseny lelle',
      ]),
      ['Verseny lelle', 'Verseny kekszalag', 'Kezi evadzaro'],
    );
  });

  testWidgets('sorts by distance from the header', (tester) async {
    // ARRANGE
    await pumpApp(tester);
    await tester.tap(find.text('ÖSSZES'));
    await tester.pumpAndSettle();
    await showTable(tester);

    // ACT: a tav mennyiseg, az elso kattintas csokkeno.
    await tester.tap(find.text('TÁV'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(
      namesTopDown(tester, [
        'Kezi evadzaro',
        'Verseny kekszalag',
        'Verseny lelle',
      ]),
      ['Verseny kekszalag', 'Kezi evadzaro', 'Verseny lelle'],
    );
  });

  testWidgets('opens the detail when a row is tapped', (tester) async {
    // ARRANGE
    await pumpApp(tester);
    await showTable(tester);

    // ACT
    await tester.tap(find.text('Verseny lelle'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.byType(RaceDetailScreen), findsOneWidget);
  });

  testWidgets('keeps the table view after returning from the detail', (
    tester,
  ) async {
    // ARRANGE
    await pumpApp(tester);
    await showTable(tester);
    await tester.tap(find.text('Verseny lelle'));
    await tester.pumpAndSettle();

    // ACT: a BackButton sugoja magyar ("Vissza"), ezert nem pageBack.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.byType(RaceTable), findsOneWidget);
  });
}
