import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/lab_sample_tables.dart';

void main() {
  LabSample labSample({
    required int season,
    PolarSampleSource source = PolarSampleSource.telemetry,
    double stwKnots = 5,
    int seconds = 60,
  }) => LabSample(
    raceId: 'r1',
    season: season,
    source: source,
    absTwaDeg: 60,
    twsKnots: 10,
    stwKnots: stwKnots,
    seconds: seconds,
  );

  group('seasonSourcesOf', () {
    test('lists the pairs by season, then by source order', () {
      final pairs = seasonSourcesOf([
        labSample(season: 2026, source: PolarSampleSource.legacyTrack),
        labSample(season: 2024, source: PolarSampleSource.legacyTrack),
        labSample(season: 2026),
      ]);

      expect(pairs, [
        (season: 2024, source: PolarSampleSource.legacyTrack),
        (season: 2026, source: PolarSampleSource.telemetry),
        (season: 2026, source: PolarSampleSource.legacyTrack),
      ]);
    });
  });

  group('minutesOf', () {
    test('rounds the total time to minutes', () {
      expect(minutesOf([labSample(season: 2026, seconds: 89)]), 1);
      expect(minutesOf([labSample(season: 2026, seconds: 90)]), 2);
      expect(minutesOf([]), 0);
    });
  });

  group('weightedMedianStwOf', () {
    test('takes the lower median by time', () {
      final median = weightedMedianStwOf([
        labSample(season: 2026, stwKnots: 6.8, seconds: 600),
        labSample(season: 2026, stwKnots: 3.4, seconds: 300),
      ]);

      expect(median, 6.8);
      expect(weightedMedianStwOf([]), isNull);
    });
  });

  group('tableNumber', () {
    test('drops the decimals of a whole number and rounds the rest', () {
      expect(tableNumber(15), '15');
      expect(tableNumber(2.5), '2.5');
      expect(tableNumber(1.26), '1.3');
    });
  });
}
