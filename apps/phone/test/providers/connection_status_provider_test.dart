import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/connection_status_provider.dart';
import 'package:phone/providers/engine_session_provider.dart';
import 'package:phone/providers/engine_session_state.dart';
import 'package:phone/providers/race_snapshot_provider.dart';

void main() {
  final clock = DateTime.utc(2026, 5, 28, 10);

  RaceSnapshot snapshotWith(ConnectionStatus status) => RaceSnapshot(
    eventCount: 1,
    boatState: BoatState(lastUpdate: clock),
    connectionStatus: status,
    tickTime: clock,
  );

  ProviderContainer makeContainer(
    RaceSnapshot? snapshot, {
    EngineSessionState session = const EngineRunning(
      cause: EngineStartCause.user,
    ),
  }) {
    final container = ProviderContainer(
      overrides: [
        raceSnapshotProvider.overrideWith(() => _FixedSnapshot(snapshot)),
        engineSessionProvider.overrideWith(() => _FixedSession(session)),
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

    test('próba közben, snapshot nélkül → Connecting', () {
      expect(
        makeContainer(
          null,
          session: const EngineProbing(),
        ).read(connectionStatusProvider),
        const Connecting(),
      );
    });

    test('álló engine, snapshot nélkül → Disconnected (nincs mire várni)', () {
      // A kézi „Leállítás" után a pillanatkép-tükör null-ra vált.
      expect(
        makeContainer(
          null,
          session: const EngineStopped(),
        ).read(connectionStatusProvider),
        const Disconnected(),
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

class _FixedSession extends EngineSessionNotifier {
  _FixedSession(this._session);

  final EngineSessionState _session;

  @override
  EngineSessionState build() => _session;
}
