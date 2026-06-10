import 'dart:io';

import 'package:domain/domain.dart';
import 'package:prediction_probe/prediction_probe.dart';
import 'package:test/test.dart';

/// A 2026-06-06-i Balaton-verseny (VK-BS-VK pálya) determinista
/// replay-fixture tesztje: a log a VALÓDI use case-eken átfuttatva a
/// vízen + a kézi probe-futtatásokban megfigyelt viselkedést rögzíti
/// regresszióként (ADR 0020/0021).
///
/// Fixture: `test/fixtures/replay_2026_06_06.tsv` — a teljes vízi log
/// RMC + MWV(T) sorokra szűrt kivonata (a motor pozíció/SOG/COG
/// forrása az RMC, a bow-TWA forrása az MWV true).
void main() {
  const vkPosition = Coordinate(latitude: 46.946554, longitude: 18.012115);
  const bsPosition = Coordinate(latitude: 46.931763, longitude: 18.045607);

  late ReplayReport report;

  setUpAll(() {
    final lines = File(
      'test/fixtures/replay_2026_06_06.tsv',
    ).readAsLinesSync();
    report = PredictionReplay(
      marks: const [
        Mark(sequence: 1, name: 'VK', position: vkPosition),
        Mark(sequence: 2, name: 'BS', position: bsPosition),
        Mark(sequence: 3, name: 'VK2', position: vkPosition),
      ],
      // 15 mp-es mintavétel: a bója körüli ~fél perces 50 m-es
      // freeze-ablakot is biztosan lefedi (60 mp-nél kimaradhatna).
      sampleInterval: const Duration(seconds: 15),
    ).run(lines);
  });

  test('rounds VK then BS in order', () {
    // A cél-VK (3. bója) megkerülése a log végpontjától függ, ezért
    // csak az első két megkerülést rögzítjük szigorúan.
    expect(report.roundings.length, greaterThanOrEqualTo(2));
    expect(report.roundings[0].rounded.name, 'VK');
    expect(report.roundings[1].rounded.name, 'BS');
  });

  test('predicts starboard TWA near the VK-BS leg bearing before VK', () {
    final values = _predictionsBefore(
      report,
      report.roundings[0].at,
      window: const Duration(minutes: 5),
    );
    expect(values, isNotEmpty);
    // A csapásváltó körül egy-egy minta kilóghat; a közeli (5 perces)
    // ablak mediánját kapuzzuk, hogy egyetlen kiugró érték ne döntsön.
    // bearing(VK->BS) ~ 123 fok; jobb csapás.
    expect(_median(values), inInclusiveRange(110, 135));
  });

  test('predicts port TWA before BS', () {
    final values = _predictionsBefore(
      report,
      report.roundings[1].at,
      window: const Duration(minutes: 5),
    );
    expect(values, isNotEmpty);
    // A bója láb elején a csapásváltó tágabban szór (megfigyelt
    // ~bal 80-97 fok); a megkerülés előtti 5 perc tiszta bal 47-57
    // fok. A medián kapuzása robusztus a belépő kiugrásokra.
    expect(_median(values), inInclusiveRange(-65, -40));
  });

  test('freezes the prediction inside the 50 m mark radius', () {
    // ADR 0021 D4: a freeze-körön belül nincs köv-szár-TWA, a többi
    // mező (distance, bearing, ETA) él. Csak a nem-utolsó lábakat
    // nézzük, hogy a freeze-t és ne az utolsó-láb-null-t mérjük.
    final inside = report.samples
        .where(
          (s) =>
              s.nextMark != null &&
              s.prediction != null &&
              s.prediction!.distanceToMark.meters <= 50,
        )
        .toList();
    expect(inside, isNotEmpty);
    for (final sample in inside) {
      expect(sample.prediction?.predictedTwaAtMark, isNull);
    }
  });

  test('returns no prediction on the final leg', () {
    // ADR 0021 D2: utolsó láb (nincs nextMark) -> predikció null.
    final lastLeg = report.samples
        .where((s) => s.activeMark?.name == 'VK2' && s.prediction != null)
        .toList();
    expect(lastLeg, isNotEmpty);
    for (final sample in lastLeg) {
      expect(sample.prediction?.predictedTwaAtMark, isNull);
    }
  });

  test('derives mostly live TWD while racing', () {
    // Verseny közben a SOG jellemzően a kapu fölött van -> a minták
    // többsége live minőségű derivált TWD (ADR 0020 D2).
    final live = report.samples
        .where((s) => s.twdQuality == TwdQuality.live)
        .length;
    expect(live, greaterThan(report.samples.length ~/ 2));
  });
}

/// Egy érték-lista mediánja; a lista nem lehet üres. Páros
/// elemszámnál a két középső számtani közepe.
double _median(List<double> values) {
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

/// Az [upTo] előtti [window]-ba eső minták nem-null predikció-fokai
/// (a freeze-körön belüli és trend nélküli minták kiesnek, mert ott a
/// predikció null).
List<double> _predictionsBefore(
  ReplayReport report,
  DateTime upTo, {
  required Duration window,
}) {
  final from = upTo.subtract(window);
  final values = <double>[];
  for (final sample in report.samples) {
    if (sample.at.isBefore(from) || !sample.at.isBefore(upTo)) {
      continue;
    }
    final twa = sample.prediction?.predictedTwaAtMark;
    if (twa != null) {
      values.add(twa.degrees);
    }
  }
  return values;
}
