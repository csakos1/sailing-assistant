import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/engine_session_provider.dart';
import 'package:phone/providers/engine_session_state.dart';
import 'package:phone/providers/gateway_probe_loop_provider.dart';
import 'package:phone/providers/gateway_probe_provider.dart';
import 'package:phone/providers/timer_factory_provider.dart';

import '../engine/fake_timers.dart';

void main() {
  late FakeTimers timers;
  late List<Completer<bool>> probes;
  late ProviderContainer container;

  setUp(() {
    timers = FakeTimers();
    probes = [];
    container = ProviderContainer(
      overrides: [
        timerFactoryProvider.overrideWithValue(timers.create),
        gatewayProbeProvider.overrideWithValue(() {
          final probe = Completer<bool>();
          probes.add(probe);
          return probe.future;
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(gatewayProbeLoopProvider, (_, _) {});
  });

  test('no probe while stopped', () {
    expect(probes, isEmpty);
  });

  test('probing runs the probe, a hit runs the engine', () async {
    // Act
    container.read(engineSessionProvider.notifier).appResumed();

    // Assert
    expect(probes, hasLength(1));

    // Act
    probes.single.complete(true);
    await pumpEventQueue();

    // Assert
    expect(container.read(engineSessionProvider), isA<EngineRunning>());
  });

  test('going to the background stops the loop', () async {
    // Arrange
    container.read(engineSessionProvider.notifier).appResumed();
    probes.single.complete(false);
    await pumpEventQueue();

    // Act
    container.read(engineSessionProvider.notifier).appPaused();

    // Assert
    expect(timers.active, isEmpty);
  });

  test('a manual start while probing stops the loop', () async {
    // Arrange
    container.read(engineSessionProvider.notifier).appResumed();

    // Act: the late hit of the stopped probe must not count.
    container.read(engineSessionProvider.notifier).startManually();
    probes.single.complete(true);
    await pumpEventQueue();

    // Assert
    expect(timers.active, isEmpty);
    final running = container.read(engineSessionProvider) as EngineRunning;
    expect(running.cause, EngineStartCause.user);
  });
}
