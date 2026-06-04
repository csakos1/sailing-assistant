import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/connection_status_provider.dart';
import 'package:phone/providers/race_snapshot_provider.dart';

void main() {
  final clock = DateTime.utc(2026, 5, 28, 10);

  RaceSnapshot snapshotWith(ConnectionStatus status) => RaceSnapshot(
    eventCount: 1,
    boatState: BoatState(lastUpdate: clock),
    connectionStatus: status,
    tickTime: clock,
  );

  ProviderContainer makeContainer(RaceSnapshot? snapshot) {
    final container = ProviderContainer(
      overrides: [
        raceSnapshotProvider.overrideWith(() => _FixedSnapshot(snapshot)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('connectionStatusProvider', () {
    test('nincs snapshot → Connecting (várjuk az első pillanatképet)', () {
      expect(
        makeContainer(null).read(connectionStatusProvider),
        const Connecting(),
      );
    });

    test('snapshot → a connectionStatus-t tükrözi', () {
      expect(
        makeContainer(
          snapshotWith(const Connected()),
        ).read(connectionStatusProvider),
        const Connected(),
      );
    });

    test('a ConnectionError üzenetet megőrzi', () {
      final state = makeContainer(
        snapshotWith(const ConnectionError('Kapcsolat megszakadt')),
      ).read(connectionStatusProvider);
      expect(state, isA<ConnectionError>());
      expect((state as ConnectionError).message, 'Kapcsolat megszakadt');
    });
  });
}

class _FixedSnapshot extends RaceSnapshotNotifier {
  _FixedSnapshot(this._snapshot);

  final RaceSnapshot? _snapshot;

  @override
  RaceSnapshot? build() => _snapshot;
}
