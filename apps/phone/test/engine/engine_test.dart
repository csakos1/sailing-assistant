import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:phone/engine/engine_heartbeat.dart';
import 'package:phone/engine/race_engine_host.dart';

void main() {
  group('EngineHeartbeat', () {
    test('toMap → fromMap round-trip megőrzi a mezőket és az UTC-t', () {
      // Arrange
      final original = EngineHeartbeat(
        tickCount: 42,
        timestamp: DateTime.utc(2026, 6, 3, 12, 30, 15),
      );

      // Act
      final restored = EngineHeartbeat.fromMap(original.toMap());

      // Assert
      expect(restored.tickCount, 42);
      expect(restored.timestamp, DateTime.utc(2026, 6, 3, 12, 30, 15));
      expect(restored.timestamp.isUtc, isTrue);
    });
  });

  group('RaceEngineHost (fake-fel a szerződésre)', () {
    test('start/stop billenti az isStarted jelzőt', () async {
      // Arrange
      final host = _FakeRaceEngineHost();
      addTearDown(host.dispose);

      // Act & Assert
      expect(host.isStarted, isFalse);
      await host.start();
      expect(host.isStarted, isTrue);
      await host.stop();
      expect(host.isStarted, isFalse);
    });

    test('emit eljut a heartbeats streamre', () async {
      // Arrange
      final host = _FakeRaceEngineHost();
      addTearDown(host.dispose);
      final received = <EngineHeartbeat>[];
      final sub = host.heartbeats.listen(received.add);

      // Act
      host.emit(EngineHeartbeat(tickCount: 7, timestamp: DateTime.utc(2026)));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // Assert
      expect(received, hasLength(1));
      expect(received.single.tickCount, 7);
    });
  });
}

/// Teszt-fake: valódi service nélkül implementálja a szerződést.
class _FakeRaceEngineHost implements RaceEngineHost {
  final StreamController<EngineHeartbeat> _controller =
      StreamController<EngineHeartbeat>.broadcast();

  bool isStarted = false;

  @override
  Stream<EngineHeartbeat> get heartbeats => _controller.stream;

  void emit(EngineHeartbeat heartbeat) => _controller.add(heartbeat);

  @override
  Future<void> start() async {
    isStarted = true;
  }

  @override
  Future<void> stop() async {
    isStarted = false;
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
