import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/engine/free_mode_idle_watch.dart';

import 'fake_timers.dart';

void main() {
  const timeout = Duration(minutes: 10);

  late FakeTimers timers;
  late int idleCount;
  late FreeModeIdleWatch watch;

  setUp(() {
    timers = FakeTimers();
    idleCount = 0;
    watch = FreeModeIdleWatch(
      timeout: timeout,
      onIdle: () => idleCount++,
      createTimer: timers.create,
    );
  });

  test('free mode without a snapshot arms the timeout', () {
    // Act
    watch.begin(isFreeMode: true);

    // Assert
    expect(timers.active.single.duration, timeout);
  });

  test('a race at start does not arm it', () {
    // Act
    watch.begin(isFreeMode: false);

    // Assert
    expect(timers.active, isEmpty);
  });

  test('the timeout reports idle once', () {
    // Arrange
    watch.begin(isFreeMode: true);

    // Act
    timers.active.single.fire();

    // Assert
    expect(idleCount, 1);
  });

  test('a connection cancels it, a drop arms a fresh one', () {
    // Arrange
    watch.begin(isFreeMode: true);
    final first = timers.active.single;

    // Act
    watch.observe(raceStatus: null, connectionStatus: const Connected());

    // Assert
    expect(first.isActive, isFalse);
    expect(timers.active, isEmpty);

    // Act
    watch.observe(raceStatus: null, connectionStatus: const Connecting());

    // Assert
    expect(timers.active, hasLength(1));
    expect(timers.created, hasLength(2));
  });

  test('repeated disconnected snapshots keep the same timer', () {
    // Arrange
    watch.begin(isFreeMode: true);

    // Act
    for (var i = 0; i < 3; i++) {
      watch.observe(raceStatus: null, connectionStatus: const Disconnected());
    }

    // Assert
    expect(timers.created, hasLength(1));
  });

  test('before the start and during a race it never arms', () {
    // Arrange / Act
    watch
      ..begin(isFreeMode: true)
      ..observe(
        raceStatus: RaceStatus.notStarted,
        connectionStatus: const ConnectionError('gone'),
      );

    // Assert
    expect(timers.active, isEmpty);

    // Act
    watch.observe(
      raceStatus: RaceStatus.active,
      connectionStatus: const Disconnected(),
    );

    // Assert
    expect(timers.active, isEmpty);
  });

  test('a finished race counts as free mode', () {
    // Arrange / Act
    watch
      ..begin(isFreeMode: false)
      ..observe(
        raceStatus: RaceStatus.finished,
        connectionStatus: const Disconnected(),
      );

    // Assert
    expect(timers.active, hasLength(1));
  });

  test('end cancels the timer and ignores later snapshots', () {
    // Arrange / Act
    watch
      ..begin(isFreeMode: true)
      ..end()
      ..observe(raceStatus: null, connectionStatus: const Disconnected());

    // Assert
    expect(timers.active, isEmpty);
    expect(idleCount, 0);
  });
}
