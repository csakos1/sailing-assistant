import 'dart:async';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/engine/race_engine_host.dart';

void main() {
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

    test('emit eljut a snapshots streamre', () async {
      // Arrange
      final host = _FakeRaceEngineHost();
      addTearDown(host.dispose);
      final received = <RaceSnapshot>[];
      final sub = host.snapshots.listen(received.add);

      // Act
      host.emit(
        RaceSnapshot(
          eventCount: 7,
          boatState: BoatState(lastUpdate: DateTime.utc(2026)),
          connectionStatus: const Connected(),
          tickTime: DateTime.utc(2026),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // Assert
      expect(received, hasLength(1));
      expect(received.single.eventCount, 7);
    });
  });
}

/// Teszt-fake: valódi service nélkül implementálja a szerződést.
class _FakeRaceEngineHost implements RaceEngineHost {
  final StreamController<RaceSnapshot> _controller =
      StreamController<RaceSnapshot>.broadcast();

  bool isStarted = false;

  @override
  Stream<RaceSnapshot> get snapshots => _controller.stream;

  void emit(RaceSnapshot snapshot) => _controller.add(snapshot);

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
