import 'dart:async';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/engine/race_engine_host.dart';
import 'package:phone/providers/race_engine_host_provider.dart';
import 'package:phone/providers/race_snapshot_provider.dart';

void main() {
  RaceSnapshot snapshotWith(int eventCount) => RaceSnapshot(
    eventCount: eventCount,
    boatState: BoatState(lastUpdate: DateTime.utc(2026)),
    connectionStatus: const Connected(),
    tickTime: DateTime.utc(2026),
  );

  late _FakeRaceEngineHost host;

  ProviderContainer makeContainer() {
    host = _FakeRaceEngineHost();
    final container = ProviderContainer(
      overrides: [raceEngineHostProvider.overrideWithValue(host)],
    )..listen(raceSnapshotProvider, (_, _) {});
    addTearDown(host.dispose);
    addTearDown(container.dispose);
    return container;
  }

  group('raceSnapshotProvider', () {
    test('snapshot előtt → null', () {
      // Arrange / Act
      final container = makeContainer();

      // Assert
      expect(container.read(raceSnapshotProvider), isNull);
    });

    test('emit után a legfrissebb snapshotot tartja', () async {
      // Arrange
      final container = makeContainer();

      // Act
      host.emit(snapshotWith(7));
      await pumpEventQueue();

      // Assert
      expect(container.read(raceSnapshotProvider)?.eventCount, 7);
    });

    test('latest-wins: a második emit felülírja az elsőt', () async {
      // Arrange
      final container = makeContainer();

      // Act
      host
        ..emit(snapshotWith(1))
        ..emit(snapshotWith(2));
      await pumpEventQueue();

      // Assert
      expect(container.read(raceSnapshotProvider)?.eventCount, 2);
    });
  });
}

/// Teszt-fake: kontrollált snapshot-streammel implementálja a szerződést.
class _FakeRaceEngineHost implements RaceEngineHost {
  final StreamController<RaceSnapshot> _controller =
      StreamController<RaceSnapshot>.broadcast();

  @override
  void sendRoundMarkCommand() {}

  @override
  Stream<RaceSnapshot> get snapshots => _controller.stream;

  void emit(RaceSnapshot snapshot) => _controller.add(snapshot);

  @override
  Future<String?> start(Race race) async => null;

  @override
  void sendStartCommand(DateTime at) {}

  @override
  void sendFinishCommand(DateTime at) {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
