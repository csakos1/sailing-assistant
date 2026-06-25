import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_detail/widgets/post_race_analysis_section.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/rounding_sample_reader_provider.dart';

void main() {
  // Szintetikus A->B folyam: 10 'A' tick (predikcio -120, high, sav 5), majd
  // 31 'B' tick (tenyleges -117, a COG = leg-irany -> a kapu nyit). Egy
  // megkereles: delta = +3, savon belul (ADR 0026/0034).
  List<RoundingSample> scenario() {
    final base = DateTime.utc(2026, 6, 6, 11);
    return <RoundingSample>[
      for (var i = 0; i < 10; i++)
        RoundingSample(
          tickTime: base.add(Duration(seconds: i)),
          raceStatus: 'active',
          twdQuality: 'live',
          markName: 'A',
          predictedTwaAtMarkDeg: -120,
          shiftConfidence: 'high',
          forecastBandDeg: 5,
          currentTwaDeg: -120,
        ),
      for (var i = 0; i < 31; i++)
        RoundingSample(
          tickTime: base.add(Duration(seconds: 10 + i)),
          raceStatus: 'active',
          twdQuality: 'live',
          markName: 'B',
          currentTwaDeg: -117,
          bearingToMarkDeg: 90,
          cogDeg: 90,
        ),
    ];
  }

  Future<void> pumpSection(
    WidgetTester tester, {
    required RoundingSampleReader reader,
  }) {
    final container = ProviderContainer(
      overrides: [roundingSampleReaderProvider.overrideWithValue(reader)],
    );
    addTearDown(container.dispose);
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('hu'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostRaceAnalysisSection(raceId: 'r1'),
            ),
          ),
        ),
      ),
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) => AppLocalizations.of(
    tester.element(find.byType(PostRaceAnalysisSection)),
  )!;

  testWidgets('adat eseten az osszegzo es a megkereles-kartya latszik', (
    tester,
  ) async {
    // ARRANGE + ACT
    await pumpSection(tester, reader: (_) async => scenario());
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    // ASSERT — a from->to fejlec + osszegzo cimke lathato, nincs ures-allapot.
    expect(find.text('A → B'), findsOneWidget);
    expect(find.text(l10n.detailAnalysisAvgDelta), findsOneWidget);
    expect(find.text(l10n.detailAnalysisEmpty), findsNothing);
  });

  testWidgets('ures reader eseten az ures-allapot latszik', (tester) async {
    // ARRANGE + ACT — nincs rogzitett snapshot a versenyhez (ADR 0034 D5).
    await pumpSection(tester, reader: (_) async => const <RoundingSample>[]);
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    // ASSERT
    expect(find.text(l10n.detailAnalysisEmpty), findsOneWidget);
  });
}
