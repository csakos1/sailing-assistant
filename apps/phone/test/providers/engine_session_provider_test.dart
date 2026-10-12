import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/engine_session_provider.dart';
import 'package:phone/providers/engine_session_state.dart';

void main() {
  late ProviderContainer container;

  EngineSessionNotifier session() =>
      container.read(engineSessionProvider.notifier);
  EngineSessionState state() => container.read(engineSessionProvider);

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('starts stopped: the boot restore does not start the engine', () {
    expect(state(), isA<EngineStopped>());
  });

  test('foreground starts probing, background pauses it', () {
    // Act
    session().appResumed();

    // Assert
    expect(state(), isA<EngineProbing>());

    // Act
    session().appPaused();

    // Assert
    expect(state(), isA<EngineStopped>());
  });

  test('a found gateway runs the engine with the gatewayFound cause', () {
    // Arrange
    session().appResumed();

    // Act
    session().gatewayFound();

    // Assert
    final running = state() as EngineRunning;
    expect(running.cause, EngineStartCause.gatewayFound);
  });

  test('a found gateway is ignored unless probing', () {
    // Act
    session().gatewayFound();

    // Assert
    expect(state(), isA<EngineStopped>());
  });

  test('background does not stop a running engine', () {
    // Arrange
    session()
      ..appResumed()
      ..gatewayFound();

    // Act
    session().appPaused();

    // Assert
    expect(state(), isA<EngineRunning>());
  });

  test('a manual start runs from any state, but never restarts', () {
    // Act
    session().startManually();

    // Assert
    final running = state() as EngineRunning;
    expect(running.cause, EngineStartCause.user);

    // Act: a second call keeps the very same state.
    session().startManually();

    // Assert
    expect(identical(state(), running), isTrue);
  });

  test('a running service is adopted from stopped or probing', () {
    // Act
    session().adoptRunningEngine();

    // Assert
    final running = state() as EngineRunning;
    expect(running.cause, EngineStartCause.adopted);

    // Act: a later adoption keeps the running state.
    session().adoptRunningEngine();

    // Assert
    expect(identical(state(), running), isTrue);
  });

  test('a manual stop waits for the next foreground to probe again', () {
    // Arrange
    session()
      ..appResumed()
      ..gatewayFound();

    // Act
    session().stopManually();

    // Assert
    expect(state(), isA<EngineStopped>());

    // Act
    session()
      ..appPaused()
      ..appResumed();

    // Assert
    expect(state(), isA<EngineProbing>());
  });

  test('a repeated foreground signal does not undo a manual stop', () {
    // Arrange
    session()
      ..appResumed()
      ..gatewayFound()
      ..stopManually();

    // Act
    session().appResumed();

    // Assert
    expect(state(), isA<EngineStopped>());
  });

  test('idle stop probes again in the foreground', () {
    // Arrange
    session()
      ..appResumed()
      ..gatewayFound();

    // Act
    session().stopAfterIdle();

    // Assert
    expect(state(), isA<EngineProbing>());
  });

  test('idle stop in the background just stops', () {
    // Arrange
    session()
      ..appResumed()
      ..gatewayFound()
      ..appPaused();

    // Act
    session().stopAfterIdle();

    // Assert
    expect(state(), isA<EngineStopped>());
  });

  test('a failed start stops without probing again', () {
    // Arrange
    session()
      ..appResumed()
      ..gatewayFound();

    // Act
    session().startFailed();

    // Assert
    expect(state(), isA<EngineStopped>());
  });

  test('idle stop and failed start are ignored unless running', () {
    // Arrange
    session().appResumed();

    // Act
    session()
      ..stopAfterIdle()
      ..startFailed();

    // Assert
    expect(state(), isA<EngineProbing>());
  });
}
