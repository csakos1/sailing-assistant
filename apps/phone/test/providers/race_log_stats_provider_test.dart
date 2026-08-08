import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/race_log_provider.dart';
import 'package:phone/providers/race_log_stats_provider.dart';
import 'package:phone/providers/race_track_stats_provider.dart';
import 'package:phone/providers/track_sample_reader_provider.dart';

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
  // aggregalas (csak a kivalasztott ev) ellenorizheto legyen. A
  // gyorsitotarat egy memoriabeli terkep jatssza: az iro ide teszi be a
  // kiszamolt statisztikat, az olvaso innen adja vissza.
  ({
    ProviderContainer container,
    List<String> requested,
    Map<String, TrackStats> cache,
    List<int> writtenSampleCounts,
  })
  containerFor({
    required List<RaceLogYear> years,
    required Map<String, List<TrackSample>> samples,
    Map<String, TrackStats> cached = const {},
  }) {
    final requested = <String>[];
    final cache = <String, TrackStats>{...cached};
    final writtenSampleCounts = <int>[];

    Future<TrackStats?> readCache(String raceId) async => cache[raceId];

    Future<void> writeCache(
      String raceId,
      TrackStats stats, {
      required int sampleCount,
      required DateTime computedAt,
    }) async {
      cache[raceId] = stats;
      writtenSampleCounts.add(sampleCount);
    }

    final container = ProviderContainer(
      overrides: [
        raceLogProvider.overrideWith((ref) => AsyncValue.data(years)),
        trackSampleReaderProvider.overrideWith((ref) {
          return (raceId) async {
            requested.add(raceId);
            return samples[raceId] ?? const <TrackSample>[];
          };
        }),
        raceTrackStatsReaderProvider.overrideWith((ref) => readCache),
        raceTrackStatsWriterProvider.overrideWith((ref) => writeCache),
      ],
    );
    addTearDown(container.dispose);
    return (
      container: container,
      requested: requested,
      cache: cache,
      writtenSampleCounts: writtenSampleCounts,
    );
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

    test('uses the cached stats instead of reading samples', () async {
      // ARRANGE - a verseny statisztikaja mar materializalva van, es a
      // mintak szandekosan mas szamokat adnanak.
      final fixture = containerFor(
        years: [
          logYear(
            year: 2026,
            races: [finishedRace(id: 'a', year: 2026, hours: 2)],
          ),
        ],
        samples: {
          'a': [sample(sogMps: 99, latDeg: 46.90, lonDeg: 18.05)],
        },
        cached: const {'a': TrackStats(maxSpeedMps: 7, distanceMeters: 1200)},
      );

      // ACT
      final totals = await fixture.container.read(
        raceLogTrackTotalsProvider.future,
      );

      // ASSERT - a mintakat el sem olvasta, a tarolt szamokat adta vissza.
      expect(fixture.requested, isEmpty);
      expect(totals.maxSpeedMps, 7);
      expect(totals.distanceMeters, 1200);
    });

    test('backfills the cache for a race that has no row yet', () async {
      // ARRANGE - ures gyorsitotar, egy verseny ket mintaval.
      final fixture = containerFor(
        years: [
          logYear(
            year: 2026,
            races: [finishedRace(id: 'a', year: 2026, hours: 2)],
          ),
        ],
        samples: {
          'a': [
            sample(sogMps: 4, latDeg: 46.90, lonDeg: 18.05),
            sample(sogMps: 6, latDeg: 46.91, lonDeg: 18.05),
          ],
        },
      );

      // ACT
      final totals = await fixture.container.read(
        raceLogTrackTotalsProvider.future,
      );

      // ASSERT - a mintakat beolvasta, es az eredmenyt ki is irta a
      // gyorsitotarba, a bejart mintak szamaval egyutt.
      expect(fixture.requested, ['a']);
      expect(fixture.cache['a']?.maxSpeedMps, 6);
      expect(fixture.cache['a']?.distanceMeters, totals.distanceMeters);
      expect(fixture.writtenSampleCounts, [2]);
    });

    test('stops reading once the provider is disposed', () async {
      // ARRANGE - az elso verseny olvasasa egy kapun var, igy a ciklus
      // biztosan fut, amikor a kepernyot elhagyjuk.
      final gate = Completer<List<TrackSample>>();
      final requested = <String>[];
      final container = ProviderContainer(
        overrides: [
          raceLogProvider.overrideWith(
            (ref) => AsyncValue.data([
              logYear(
                year: 2026,
                races: [
                  finishedRace(id: 'first', year: 2026, hours: 2),
                  finishedRace(id: 'second', year: 2026, hours: 2),
                ],
              ),
            ]),
          ),
          trackSampleReaderProvider.overrideWith((ref) {
            return (raceId) {
              requested.add(raceId);
              if (raceId == 'first') return gate.future;
              return Future.value(const <TrackSample>[]);
            };
          }),
          // Ures gyorsitotar: minden verseny a minta-olvasoig jut el.
          raceTrackStatsReaderProvider.overrideWith(
            (ref) =>
                (raceId) async => null,
          ),
          raceTrackStatsWriterProvider.overrideWith((ref) => _ignoreWrite),
        ],
      )..read(raceLogTrackTotalsProvider);
      await Future<void>.delayed(Duration.zero);

      // ACT - a kepernyo elhagyasa, majd az elso olvasas befejezese.
      container.dispose();
      gate.complete(const <TrackSample>[]);
      await Future<void>.delayed(Duration.zero);

      // ASSERT - a masodik versenyt mar nem olvasta be.
      expect(requested, ['first']);
    });
  });
}

/// A gyorsitotar-iro semmit nem csinalo dublore a teszthez.
Future<void> _ignoreWrite(
  String raceId,
  TrackStats stats, {
  required int sampleCount,
  required DateTime computedAt,
}) async {}
