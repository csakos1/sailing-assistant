import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/gnss_clock.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/gnss_clock_provider.dart';
import 'package:phone/providers/true_time_provider.dart';

void main() {
  final fixUtc = DateTime.utc(2026, 5, 24, 9, 6, 47);
  final wallNow = DateTime.utc(2026, 5, 24, 11);

  ProviderContainer makeContainer({
    required GnssClock gnss,
    DateTime Function()? wall,
  }) {
    final container = ProviderContainer(
      overrides: [
        gnssClockProvider.overrideWithValue(gnss),
        if (wall != null) clockProvider.overrideWithValue(wall),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('első attempt előtt → none (üres cella)', () {
    // ARRANGE — a burst nem cseng le (a teszt nem pumpol)
    final container = makeContainer(gnss: () => Stream<DateTime>.value(fixUtc));

    // ACT — azonnal olvasunk, mielőtt az async burst lefutna
    final reading = container.read(trueTimeProvider)();

    // ASSERT
    expect(reading.source, TrueTimeSource.none);
    expect(reading.utc, isNull);
  });

  test(
    'sikeres GNSS-fix (egy mintás burst) → gnss forrás, nem-null idő',
    () async {
      // ARRANGE
      final container = makeContainer(
        gnss: () => Stream<DateTime>.value(fixUtc),
      );

      // ACT — a build elindítja a burstöt, megvárjuk a lecsengést
      final read = container.read(trueTimeProvider);
      await pumpEventQueue();
      final reading = read();

      // ASSERT — a forrás-wiring; a pontos extrapolációt a pure teszt fedi
      expect(reading.source, TrueTimeSource.gnss);
      expect(reading.utc, isNotNull);
    },
  );

  test('üres burst (nincs minta) → wallClockUnsynced fallback', () async {
    // ARRANGE — a stream nem ad mintát
    final container = makeContainer(
      gnss: Stream<DateTime>.empty,
      wall: () => wallNow,
    );

    // ACT
    final read = container.read(trueTimeProvider);
    await pumpEventQueue();
    final reading = read();

    // ASSERT
    expect(reading.source, TrueTimeSource.wallClockUnsynced);
    expect(reading.utc, isNotNull);
  });
}
