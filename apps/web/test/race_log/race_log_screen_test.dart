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

import '../support/sample_summaries.dart';

// A teljes webes app a naplo-kepernyovel, valodi kliens-kodekkel es egy
// MockClient-tel a szerver helyen.

void main() {
  final summaries = [
    telemetrySummary('lelle', start: DateTime(2026, 8, 22, 11)),
    telemetrySummary('horvath', start: DateTime(2026, 7, 26, 11)),
    manualSummary('kekszalag2024', date: '2024-07-25'),
  ];

  Future<void> pumpApp(
    WidgetTester tester,
    Future<http.Response> Function(http.Request request) handler,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          archiveApiClientProvider.overrideWithValue(
            ArchiveApiClient(
              MockClient(handler),
              baseUri: Uri.parse('http://localhost/'),
            ),
          ),
        ],
        child: const ForetackWebApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<http.Response> serving(List<RaceSummary> races) async =>
      http.Response.bytes(
        utf8.encode(jsonEncode(encodeRaceSummaries(races))),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  testWidgets('shows the newest year with day and name rows', (tester) async {
    // ACT
    await pumpApp(tester, (request) => serving(summaries));

    // ASSERT
    expect(find.text('Versenynapló'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('2024'), findsOneWidget);
    expect(find.text('2 VERSENY'), findsOneWidget);
    expect(find.byType(RaceLogRow), findsNWidgets(2));
    expect(find.text('Verseny lelle'), findsOneWidget);
    expect(find.text('22'), findsOneWidget);
    expect(find.text('Kezi kekszalag2024'), findsNothing);
  });

  testWidgets('switches to another year', (tester) async {
    // ARRANGE
    await pumpApp(tester, (request) => serving(summaries));

    // ACT
    await tester.tap(find.text('2024'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('Kezi kekszalag2024'), findsOneWidget);
    expect(find.text('Verseny lelle'), findsNothing);
    expect(find.text('1 VERSENY'), findsWidgets);
    // Az evek a helyukon maradnak (ADR 0048 Addendum 7 N1).
    expect(
      tester.getTopLeft(find.text('2026')).dx,
      lessThan(tester.getTopLeft(find.text('2024')).dx),
    );
  });

  testWidgets('shows every year with year headings', (tester) async {
    // ARRANGE
    await pumpApp(tester, (request) => serving(summaries));

    // ACT
    await tester.tap(find.text('ÖSSZES'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('2024–2026'), findsOneWidget);
    expect(find.text('3 VERSENY'), findsOneWidget);
    expect(find.byType(RaceLogRow), findsNWidgets(3));
    expect(find.text('ÖSSZES'), findsNothing);
  });

  testWidgets('offers a retry after a failed load', (tester) async {
    // ARRANGE: az elso keres hibazik, a masodik sikerul
    var calls = 0;
    await pumpApp(tester, (request) async {
      calls++;
      if (calls == 1) {
        return http.Response(
          jsonEncode(encodeApiError(const InternalError())),
          500,
        );
      }
      return serving(summaries);
    });
    expect(find.text('ÚJRA'), findsOneWidget);

    // ACT
    await tester.tap(find.text('ÚJRA'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.byType(RaceLogRow), findsNWidgets(2));
    expect(calls, 2);
  });

  testWidgets('explains an empty archive', (tester) async {
    await pumpApp(tester, (request) => serving(const []));

    expect(find.textContaining('Még nincs verseny'), findsOneWidget);
    expect(find.byType(RaceLogRow), findsNothing);
  });

  Finder uploadButtonOf<T extends Widget>() => find.ancestor(
    of: find.text('Feltöltés'),
    matching: find.byType(T),
  );

  testWidgets('fills the upload button in an empty archive', (tester) async {
    // ACT: ures naplo (13b)
    await pumpApp(tester, (request) => serving(const []));

    // ASSERT
    expect(
      uploadButtonOf<FilledButton>(),
      findsOneWidget,
    );
  });

  testWidgets('outlines the upload button next to races', (tester) async {
    // ACT
    await pumpApp(tester, (request) => serving(summaries));

    // ASSERT
    expect(
      uploadButtonOf<FilledButton>(),
      findsNothing,
    );
    expect(
      uploadButtonOf<OutlinedButton>(),
      findsOneWidget,
    );
  });
}
