import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const summarize = SummarizeRoundings();
  final at = DateTime.utc(2026, 6, 6, 11);
  RoundingResult result({
    required String from,
    required String to,
    double? predicted,
    double? mark,
    double? band,
    Duration? leadTime,
  }) {
    return RoundingResult(
      fromMark: from,
      toMark: to,
      roundedAt: at,
      predictedTwaDeg: predicted,
      markTwaDeg: mark,
      forecastBandDeg: band,
      leadTime: leadTime,
    );
  }

  group('SummarizeRoundings', () {
    test('átlagol, számolja a sáv-találatot és a lead-time-ot', () {
      // ARRANGE — r1: delta 3, sávon belül (5), lead 10 s; r2: delta -17,
      // sávon kívül (5), lead 20 s; r3: nincs predikció -> nincs delta/sáv.
      final results = [
        result(
          from: 'A',
          to: 'B',
          predicted: -120,
          mark: -117,
          band: 5,
          leadTime: const Duration(seconds: 10),
        ),
        result(
          from: 'B',
          to: 'C',
          predicted: -100,
          mark: -117,
          band: 5,
          leadTime: const Duration(seconds: 20),
        ),
        result(from: 'C', to: 'D', mark: -117),
      ];

      // ACT
      final summary = summarize(results);

      // ASSERT
      expect(summary.avgAbsDeltaDeg, closeTo(10, 1e-9)); // (3 + 17) / 2
      expect(summary.bandHits, 1);
      expect(summary.bandTotal, 2);
      expect(summary.avgLeadTime, const Duration(seconds: 15));
    });

    test('üres listára null aggregátumok', () {
      // ACT
      final summary = summarize(const <RoundingResult>[]);

      // ASSERT
      expect(summary.avgAbsDeltaDeg, isNull);
      expect(summary.bandHits, 0);
      expect(summary.bandTotal, 0);
      expect(summary.avgLeadTime, isNull);
    });
  });
}
