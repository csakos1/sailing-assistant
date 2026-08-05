import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/race_log_provider.dart';
import 'package:phone/providers/race_log_stats_provider.dart';
import 'package:phone/providers/rounding_sample_reader_provider.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.9, longitude: 18.05),
  );

  Race finishedRace({
    required String id,
    required int year,
    required int hours,
  }) {
    final startedAt = DateTime(year, 5, 1, 10);
    return Race.create(
      id: id,
      name: id,
      marks: const [mark],
    ).start(at: startedAt).finish(at: startedAt.add(Duration(hours: hours)));
  }

  RaceLogYear logYear({required int year, required List<Race> races}) {
    return RaceLogYear(
      year: year,
      months: [RaceLogMonth(month: 5, races: races)],
    );
  }

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

  // A fake olvaso a kert race-id-ket is rogziti, hogy a szeletes
  // aggregalas (csak a kivalasztott ev) ellenorizheto legyen.
  ({ProviderContainer container, List<String> requested}) containerFor({
    required List<RaceLogYear> years,
    required Map<String, List<RoundingSample>> samples,
  }) {
    final requested = <String>[];
    final container = ProviderContainer(
      overrides: [
        raceLogProvider.overrideWith((ref) => AsyncValue.data(years)),
        roundingSampleReaderProvider.overrideWith((ref) {
          return (raceId) async {
            requested.add(raceId);
            return samples[raceId] ?? const <RoundingSample>[];
          };
        }),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, requested: requested);
  }

  group('raceLogTimeOnWaterProvider', () {
    test('sums the elapsed time of the selected year', () {
      final fixture = containerFor(
        years: [
          logYear(
            year: 2026,
            races: [
              finishedRace(id: 'a', year: 2026, hours: 3),
              finishedRace(id: 'b', year: 2026, hours: 2),
            ],
          ),
        ],
        samples: const {},
      );

      final total = fixture.container.read(raceLogTimeOnWaterProvider);

      expect(total, const Duration(hours: 5));
    });

    test('ignores the years that are not selected', () {
      final fixture = containerFor(
        years: [
          logYear(
            year: 2026,
            races: [finishedRace(id: 'new', year: 2026, hours: 3)],
          ),
          logYear(
            year: 2024,
            races: [finishedRace(id: 'old', year: 2024, hours: 9)],
          ),
        ],
        samples: const {},
      );

      final total = fixture.container.read(raceLogTimeOnWaterProvider);

      expect(total, const Duration(hours: 3));
    });

    test('returns zero for an empty log', () {
      final fixture = containerFor(years: const [], samples: const {});

      expect(fixture.container.read(raceLogTimeOnWaterProvider), Duration.zero);
    });
  });

  group('raceLogTrackTotalsProvider', () {
    test('adds up the distances and keeps the fastest speed', () async {
      // Ket verseny, ket-ket mintaval: a tavolsagok osszeadodnak, a
      // sebessegek kozul a legnagyobb marad.
      final fixture = containerFor(
        years: [
          logYear(
            year: 2026,
            races: [
              finishedRace(id: 'a', year: 2026, hours: 2),
              finishedRace(id: 'b', year: 2026, hours: 2),
            ],
          ),
        ],
        samples: {
          'a': [
            sample(sogMps: 4, latDeg: 46.90, lonDeg: 18.05),
            sample(sogMps: 6, latDeg: 46.91, lonDeg: 18.05),
          ],
          'b': [
            sample(sogMps: 9, latDeg: 46.80, lonDeg: 17.90),
            sample(sogMps: 5, latDeg: 46.81, lonDeg: 17.90),
          ],
        },
      );

      final totals = await fixture.container.read(
        raceLogTrackTotalsProvider.future,
      );

      expect(totals.maxSpeedMps, 9);
      expect(totals.distanceMeters, isNotNull);
      expect(totals.distanceMeters, greaterThan(0));
    });

    test('reports null when no race has usable samples', () async {
      final fixture = containerFor(
        years: [
          logYear(
            year: 2026,
            races: [finishedRace(id: 'a', year: 2026, hours: 2)],
          ),
        ],
        samples: const {},
      );

      final totals = await fixture.container.read(
        raceLogTrackTotalsProvider.future,
      );

      expect(totals.distanceMeters, isNull);
      expect(totals.maxSpeedMps, isNull);
    });

    test('reads only the races of the selected year', () async {
      final fixture = containerFor(
        years: [
          logYear(
            year: 2026,
            races: [finishedRace(id: 'new', year: 2026, hours: 2)],
          ),
          logYear(
            year: 2024,
            races: [finishedRace(id: 'old', year: 2024, hours: 2)],
          ),
        ],
        samples: {
          'new': [sample(sogMps: 3)],
          'old': [sample(sogMps: 99)],
        },
      );

      final totals = await fixture.container.read(
        raceLogTrackTotalsProvider.future,
      );

      expect(fixture.requested, ['new']);
      expect(totals.maxSpeedMps, 3);
    });

    test('returns nulls for an empty log without reading anything', () async {
      final fixture = containerFor(years: const [], samples: const {});

      final totals = await fixture.container.read(
        raceLogTrackTotalsProvider.future,
      );

      expect(fixture.requested, isEmpty);
      expect(totals.distanceMeters, isNull);
      expect(totals.maxSpeedMps, isNull);
    });
  });
}
