import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:phone/engine/gateway_probe_loop.dart';

import 'fake_timers.dart';

void main() {
  const interval = Duration(seconds: 5);

  late FakeTimers timers;
  late List<Completer<bool>> probes;
  late int foundCount;
  late GatewayProbeLoop loop;

  setUp(() {
    timers = FakeTimers();
    probes = [];
    foundCount = 0;
    loop = GatewayProbeLoop(
      probe: () {
        final probe = Completer<bool>();
        probes.add(probe);
        return probe.future;
      },
      interval: interval,
      onFound: () => foundCount++,
      createTimer: timers.create,
    );
  });

  test('start probes at once, without waiting for the interval', () {
    // Act
    loop.start();

    // Assert
    expect(probes, hasLength(1));
    expect(timers.created, isEmpty);
  });

  test('a miss waits the interval before the next probe', () async {
    // Arrange
    loop.start();

    // Act
    probes.single.complete(false);
    await pumpEventQueue();

    // Assert
    expect(timers.active.single.duration, interval);
    expect(probes, hasLength(1));

    // Act
    timers.active.single.fire();

    // Assert
    expect(probes, hasLength(2));
  });

  test('a hit stops the loop and reports once', () async {
    // Arrange
    loop.start();

    // Act
    probes.single.complete(true);
    await pumpEventQueue();

    // Assert
    expect(foundCount, 1);
    expect(loop.isRunning, isFalse);
    expect(timers.active, isEmpty);
  });

  test('a probe finishing after stop is ignored', () async {
    // Arrange / Act
    loop
      ..start()
      ..stop();
    probes.single.complete(true);
    await pumpEventQueue();

    // Assert
    expect(foundCount, 0);
    expect(timers.active, isEmpty);
  });

  test('stop cancels the pending next probe', () async {
    // Arrange
    loop.start();
    probes.single.complete(false);
    await pumpEventQueue();

    // Act
    loop.stop();

    // Assert
    expect(timers.active, isEmpty);
  });

  test('start while running does not probe twice', () {
    // Act
    loop
      ..start()
      ..start();

    // Assert
    expect(probes, hasLength(1));
  });

  test('a restart after stop ignores the old probe', () async {
    // Arrange
    loop
      ..start()
      ..stop()
      ..start();

    // Act: the first (stale) probe hits, the second misses.
    probes.first.complete(true);
    probes.last.complete(false);
    await pumpEventQueue();

    // Assert
    expect(foundCount, 0);
    expect(timers.active, hasLength(1));
  });

  test('a throwing probe, even an Error, counts as a miss', () async {
    // Arrange / Act
    GatewayProbeLoop(
      probe: () async => throw StateError('boom'),
      interval: interval,
      onFound: () => foundCount++,
      createTimer: timers.create,
    ).start();
    await pumpEventQueue();

    // Assert
    expect(foundCount, 0);
    expect(timers.active, hasLength(1));
  });
}
