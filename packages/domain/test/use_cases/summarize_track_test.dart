import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const summarize = SummarizeTrack();

  // Test-helper: egy RoundingSample csak a track-statokhoz lényeges
  // mezőkkel; a kötelező mezők fix dummy-értéket kapnak.
  RoundingSample sample({double? sogMps, double? latDeg, double? lonDeg}) {
    return RoundingSample(
      tickTime: DateTime.utc(2026),
      raceStatus: 'finished',
      twdQuality: 'live',
      sogMps: sogMps,
      latDeg: latDeg,
      lonDeg: lonDeg,
    );
  }

  group('SummarizeTrack speed stats', () {
    test('returns all-null stats for an empty sample list', () {
      final stats = summarize(const []);
      expect(stats.maxSpeedMps, isNull);
      expect(stats.avgSpeedMps, isNull);
      expect(stats.distanceMeters, isNull);
    });

    test('computes max and arithmetic mean over non-null speeds', () {
      final stats = summarize([
        sample(sogMps: 2),
        sample(sogMps: 4),
        sample(sogMps: 6),
      ]);

      expect(stats.maxSpeedMps, 6);
      expect(stats.avgSpeedMps, 4); // (2 + 4 + 6) / 3
    });

    test('ignores null speeds in both max and mean', () {
      final stats = summarize([
        sample(sogMps: 3),
        sample(), // sogMps null — kihagyva
        sample(sogMps: 5),
      ]);

      expect(stats.maxSpeedMps, 5);
      expect(stats.avgSpeedMps, 4); // (3 + 5) / 2, a null nem számít bele
    });

    test('leaves speed stats null when no sample has a speed', () {
      final stats = summarize([sample(), sample()]);

      expect(stats.maxSpeedMps, isNull);
      expect(stats.avgSpeedMps, isNull);
    });
  });

  group('SummarizeTrack distance', () {
    test('sums haversine legs between consecutive positions', () {
      // VK (46.946554, 18.012115) -> BS (46.931763, 18.045607) a
      // Balatonon; a haversine-távolság R=6371000-rel ~3028.29 m.
      final stats = summarize([
        sample(latDeg: 46.946554, lonDeg: 18.012115),
        sample(latDeg: 46.931763, lonDeg: 18.045607),
      ]);

      expect(stats.distanceMeters, closeTo(3028.29, 1));
    });

    test('returns null distance for fewer than two positions', () {
      final stats = summarize([sample(latDeg: 46.9, lonDeg: 18)]);

      expect(stats.distanceMeters, isNull);
    });

    test('chains across samples that lack a position', () {
      // A közbeeső, pozíció nélküli minta nem szakítja meg a láncot:
      // az első és a harmadik pozíció közti szakaszt számoljuk.
      final withGap = summarize([
        sample(latDeg: 46.946554, lonDeg: 18.012115),
        sample(sogMps: 3), // nincs pozíció — átugorjuk
        sample(latDeg: 46.931763, lonDeg: 18.045607),
      ]);
      final direct = summarize([
        sample(latDeg: 46.946554, lonDeg: 18.012115),
        sample(latDeg: 46.931763, lonDeg: 18.045607),
      ]);

      expect(withGap.distanceMeters, direct.distanceMeters);
    });

    test('treats a single missing coordinate as no position', () {
      // Csak a latDeg van meg, a lonDeg null -> nincs érvényes pozíció,
      // így mindössze egy érvényes pozíció marad -> null úthossz.
      final stats = summarize([
        sample(latDeg: 46.9),
        sample(latDeg: 46.8, lonDeg: 18.1),
      ]);

      expect(stats.distanceMeters, isNull);
    });
  });
}
