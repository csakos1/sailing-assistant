import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/app_foreground_binding.dart';
import 'package:phone/providers/engine_session_provider.dart';
import 'package:phone/providers/engine_session_state.dart';
import 'package:phone/providers/last_recording_reader_provider.dart';
import 'package:phone/providers/race_engine_host_provider.dart';
import 'package:phone/providers/timer_factory_provider.dart';

import '../engine/fake_timers.dart';
import '../providers/recording_engine_host.dart';

void main() {
  late RecordingEngineHost host;

  // Sends a lifecycle change the way the platform does; the binding's
  // own handler is protected.
  Future<void> sendLifecycle(
    WidgetTester tester,
    AppLifecycleState state,
  ) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
      (_) {},
    );
    // The resume first asks the host whether a service runs.
    await tester.pump();
    await tester.pump();
  }

  Future<ProviderContainer> pumpBinding(WidgetTester tester) async {
    host = RecordingEngineHost();
    addTearDown(host.close);
    final container = ProviderContainer(
      overrides: [
        raceEngineHostProvider.overrideWithValue(host),
        lastRecordingReaderProvider.overrideWithValue((_) async => null),
        // The adoption watchdog must not leave a real timer behind.
        timerFactoryProvider.overrideWithValue(FakeTimers().create),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AppForegroundBinding(child: SizedBox()),
      ),
    );
    return container;
  }

  testWidgets('resumed starts probing, hidden pauses it', (tester) async {
    // Arrange
    final container = await pumpBinding(tester);

    // Act
    await sendLifecycle(tester, AppLifecycleState.resumed);

    // Assert
    expect(container.read(engineSessionProvider), isA<EngineProbing>());

    // Act
    await sendLifecycle(tester, AppLifecycleState.inactive);
    await sendLifecycle(tester, AppLifecycleState.hidden);

    // Assert
    expect(container.read(engineSessionProvider), isA<EngineStopped>());
  });

  testWidgets('inactive does not undo a manual stop', (tester) async {
    // Arrange
    final container = await pumpBinding(tester);
    await sendLifecycle(tester, AppLifecycleState.resumed);
    container.read(engineSessionProvider.notifier)
      ..gatewayFound()
      ..stopManually();

    // Act: the notification shade is pulled down and back.
    await sendLifecycle(tester, AppLifecycleState.inactive);
    await sendLifecycle(tester, AppLifecycleState.resumed);

    // Assert
    expect(container.read(engineSessionProvider), isA<EngineStopped>());
  });

  testWidgets('a running service is adopted on resume', (tester) async {
    // Arrange
    final container = await pumpBinding(tester);
    host.isServiceRunning = true;

    // Act
    await sendLifecycle(tester, AppLifecycleState.resumed);

    // Assert
    final running = container.read(engineSessionProvider) as EngineRunning;
    expect(running.cause, EngineStartCause.adopted);
    expect(host.startedRaces, isEmpty);
  });
}
