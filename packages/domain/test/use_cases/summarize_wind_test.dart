import 'package:domain/domain.dart';
import 'package:test/test.dart';

// Teszt-minta: csak a ket szel-mennyiseg.
class _Sample implements WindSample {
  const _Sample({this.twsMps, this.twdDeg});

  @override
  final double? twsMps;

  @override
  final double? twdDeg;
}

void main() {
  const summarize = SummarizeWind();

  group('SummarizeWind speed', () {
    test('returns all-null stats for an empty sample list', () {
      final stats = summarize(const []);

      expect(stats, const WindStats());
    });

    test('computes the arithmetic mean and the raw maximum', () {
      final stats = summarize(const [
        _Sample(twsMps: 2),
        _Sample(twsMps: 4),
        _Sample(twsMps: 9),
      ]);

      expect(stats.avgWindMps, 5); // (2 + 4 + 9) / 3
      expect(stats.maxWindMps, 9);
    });

    test('ignores samples without wind speed', () {
      final stats = summarize(const [
        _Sample(twsMps: 3),
        _Sample(),
        _Sample(twsMps: 5),
      ]);

      expect(stats.avgWindMps, 4);
      expect(stats.maxWindMps, 5);
    });

    test('leaves speed null when no sample has one', () {
      final stats = summarize(const [_Sample(twdDeg: 90)]);

      expect(stats.avgWindMps, isNull);
      expect(stats.maxWindMps, isNull);
    });
  });

  group('SummarizeWind direction', () {
    test('averages across north without flipping to south', () {
      // Given: 350 es 10 fok - a szamtani atlag 180 lenne.
      final stats = summarize(const [
        _Sample(twdDeg: 350),
        _Sample(twdDeg: 10),
      ]);

      // Then: a korkoros atlag eszak, es a tartomanyon belul marad (a
      // kerekites nem adhat 360-at).
      expect(stats.directionDeg, closeTo(0, 1e-9));
    });

    test('returns a direction in the [0, 360) range for western winds', () {
      final stats = summarize(const [
        _Sample(twdDeg: 260),
        _Sample(twdDeg: 280),
      ]);

      expect(stats.directionDeg, closeTo(270, 1e-9));
    });

    test('weights every sample equally', () {
      // Given: ket minta keleten, egy deli iranyban.
      final stats = summarize(const [
        _Sample(twdDeg: 90),
        _Sample(twdDeg: 90),
        _Sample(twdDeg: 180),
      ]);

      // Then: az atlagvektor (2, -1) iranya, keletrol delfele.
      expect(stats.directionDeg, closeTo(116.565, 1e-3));
    });

    test('has no dominant direction when the samples cancel out', () {
      final stats = summarize(const [_Sample(twdDeg: 0), _Sample(twdDeg: 180)]);

      expect(stats.directionDeg, isNull);
    });

    test('ignores samples without direction', () {
      final stats = summarize(const [_Sample(twsMps: 4), _Sample(twdDeg: 45)]);

      expect(stats.directionDeg, closeTo(45, 1e-9));
    });
  });
}
