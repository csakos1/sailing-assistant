import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/boat_state_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/race_snapshot_provider.dart';

void main() {
  final clock = DateTime.utc(2026, 5, 28, 10);

  ProviderContainer makeContainer(RaceSnapshot? snapshot) {
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => clock),
        raceSnapshotProvider.overrideWith(() => _FixedSnapshot(snapshot)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('boatStateProvider', () {
    test('nincs snapshot → üres BoatState, lastUpdate az órából', () {
      // Arrange / Act
      final container = makeContainer(null);

      // Assert
      final state = container.read(boatStateProvider);
      expect(state.position, isNull);
      expect(state.lastUpdate, equals(clock));
    });

    test('snapshot jelen → a snapshot boatState-jét tükrözi', () {
      // Arrange
      const position = Coordinate(latitude: 46.9, longitude: 17.9);
      final boat = BoatState(lastUpdate: clock, position: position);
      final container = makeContainer(
        RaceSnapshot(
          eventCount: 1,
          boatState: boat,
          connectionStatus: const Connected(),
          tickTime: clock,
        ),
      );

      // Assert
      expect(container.read(boatStateProvider), equals(boat));
    });
  });
}

class _FixedSnapshot extends RaceSnapshotNotifier {
  _FixedSnapshot(this._snapshot);

  final RaceSnapshot? _snapshot;

  @override
  RaceSnapshot? build() => _snapshot;
}
