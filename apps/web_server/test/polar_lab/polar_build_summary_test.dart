import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_build.dart';
import 'package:web_server/src/polar_lab/polar_build_summary.dart';

import '../polar/polar_fixtures.dart';

void main() {
  LabSample labSample({required double twsKnots, required double stwKnots}) =>
      LabSample(
        raceId: 'r1',
        season: 2026,
        source: PolarSampleSource.telemetry,
        absTwaDeg: 60,
        twsKnots: twsKnots,
        stwKnots: stwKnots,
        seconds: 1000,
      );

  // 60 fokon 8 kn szelben 7 kn, 10 kn szelben 6 kn: az izotonikus lepes
  // mindkettot 6.5-re allitja, ami tobb mint 3%-os elteres.
  final samples = [
    labSample(twsKnots: 8, stwKnots: 7),
    labSample(twsKnots: 10, stwKnots: 6),
  ];
  final build = PolarBuild.of(allSamples: samples, steadySamples: samples);

  Polar parsed(String text) => switch (parseForetackPolar(text)) {
    Ok(:final value) => value,
    Err(:final error) => throw StateError('hibas polar: $error'),
  };

  final summary = polarBuildSummary(
    build: build,
    oldPolar: flatPolar(),
    newPolar: parsed(build.polarText),
    oldPolarLabel: 'foretack.pol (fp-1)',
  );

  group('polarBuildSummary', () {
    test('names the old polar and the season account', () {
      expect(summary, startsWith('# Polár-építés (ADR 0058)\n'));
      expect(summary, contains('`foretack.pol (fp-1)`'));
      expect(summary, contains('| 2026 | 1 | 33 | 0 | 0 | 0 | 0 | 0 | 33 |'));
      expect(summary, contains('## 7. Gyanús minták: számolt AWA'));
    });

    test('tells why the strong wind column is missing', () {
      expect(
        summary,
        contains(
          'tartományában 0 perc mért idő van (küszöb: 30 perc), ezért nem '
          'került be.',
        ),
      );
    });

    test('marks the measured, the filled and the pooled cells', () {
      expect(summary, contains('| 6.50 | 6.50 | 6.50* |'));
      expect(summary, contains('**-7.1**'));
      expect(summary, contains('**+8.3**'));
      expect(summary, contains('2 ilyen cella van.'));
      expect(
        summary,
        contains('- 60° @ 8 kn: nyers 7.00, kész 6.50 (-7.1%, 17 perc)'),
      );
    });

    test('adds the strong wind column with thirty minutes of data', () {
      final strongSamples = [
        labSample(twsKnots: 23, stwKnots: 8),
        labSample(twsKnots: 23, stwKnots: 8),
      ];
      final strongBuild = PolarBuild.of(
        allSamples: strongSamples,
        steadySamples: strongSamples,
      );

      final strongSummary = polarBuildSummary(
        build: strongBuild,
        oldPolar: flatPolar(),
        newPolar: parsed(strongBuild.polarText),
        oldPolarLabel: 'foretack.pol (fp-1)',
      );

      expect(strongBuild.polarText, startsWith('TWA/TWS;2;3;'));
      expect(strongBuild.polarText.split('\n').first, endsWith(';20;25'));
      expect(
        strongSummary,
        contains(
          'tartományában 33 perc mért idő van (küszöb: 30 perc), ezért '
          'bekerült.',
        ),
      );
    });

    test('compares the VMG optimum with the old polar', () {
      // A regi polar minden cellaja 5 kn: kreuzban a 25 fok, hatszelben a
      // 180 fok a legjobb (5 x cos 25 = 4.53).
      expect(summary, contains('| 2 | 25° / 4.53 | '));
      expect(summary, contains('| 180° / 5.00 |'));
    });
  });
}
