import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// Egy minimális `TrackSample`, ami NEM `RoundingSample`. A létezése maga a
/// bizonyíték, hogy a use case tényleg a keskeny szerződésre szűkült, és
/// nem a tizenhárom mezős read-modellre.
class _Sample implements TrackSample {
  const _Sample({this.sogMps, this.latDeg, this.lonDeg});

  @override
  final double? sogMps;

  @override
  final double? latDeg;

  @override
  final double? lonDeg;
}

void main() {
  const summarize = SummarizeTrack();

  group('SummarizeTrack TrackSample contract', () {
    test('accepts a foreign TrackSample implementation', () {
      // Arrange
      const samples = [
        _Sample(sogMps: 2, latDeg: 46.9, lonDeg: 18.05),
        _Sample(sogMps: 6, latDeg: 46.9, lonDeg: 18.06),
      ];

      // Act
      final stats = summarize(samples);

      // Assert
      expect(stats.maxSpeedMps, 6);
      expect(stats.avgSpeedMps, 4);
      expect(stats.distanceMeters, greaterThan(0));
    });

    test('still accepts the rounding sample read model', () {
      // Arrange — a meglévő fogyasztók ezt az alakot adják át.
      final samples = [
        RoundingSample(
          tickTime: DateTime.utc(2026, 5, 1, 10),
          raceStatus: 'active',
          twdQuality: 'live',
          sogMps: 4,
        ),
      ];

      // Act
      final stats = summarize(samples);

      // Assert
      expect(stats.maxSpeedMps, 4);
      expect(stats.distanceMeters, isNull);
    });

    test('mixes implementations within one list', () {
      // Arrange — a lista statikus típusa itt már TrackSample.
      final samples = <TrackSample>[
        RoundingSample(
          tickTime: DateTime.utc(2026, 5, 1, 10),
          raceStatus: 'active',
          twdQuality: 'live',
          sogMps: 3,
          latDeg: 46.9,
          lonDeg: 18.05,
        ),
        const _Sample(sogMps: 9, latDeg: 46.9, lonDeg: 18.06),
      ];

      // Act
      final stats = summarize(samples);

      // Assert
      expect(stats.maxSpeedMps, 9);
      expect(stats.avgSpeedMps, 6);
      expect(stats.distanceMeters, greaterThan(0));
    });
  });
}
