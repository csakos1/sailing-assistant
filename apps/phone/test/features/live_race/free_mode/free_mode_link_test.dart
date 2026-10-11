import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/live_race/free_mode/free_mode_link.dart';
import 'package:phone/providers/engine_session_state.dart';

final _now = DateTime.utc(2026, 7, 30, 9, 10);

const _running = EngineRunning(cause: EngineStartCause.gatewayFound);

FreeModeLink _linkOf({
  EngineSessionState session = _running,
  ConnectionStatus connection = const Connected(),
  DateTime? lastDataAt,
  DateTime? now,
}) => freeModeLinkOf(
  session: session,
  connection: connection,
  lastDataAt: lastDataAt,
  now: now,
);

void main() {
  group('freeModeLinkOf', () {
    test('a stopped engine is stopped, whatever the connection says', () {
      expect(
        _linkOf(session: const EngineStopped()),
        const FreeModeStopped(),
      );
    });

    test('a probing session is searching', () {
      expect(
        _linkOf(
          session: const EngineProbing(),
          connection: const Disconnected(),
        ),
        const FreeModeSearching(),
      );
    });

    test('a running engine that still connects is searching', () {
      expect(
        _linkOf(connection: const Connecting()),
        const FreeModeSearching(),
      );
    });

    test('reconnecting after data is a lost link, not a search', () {
      // A kliens minden ujraproba elott Connecting-et ad; adat utan ez nem
      // kereses, kulonben a csik villogna.
      final link = _linkOf(
        connection: const Connecting(),
        lastDataAt: _now.subtract(const Duration(seconds: 20)),
        now: _now,
      );

      expect(link, const FreeModeLost(dataAge: Duration(seconds: 20)));
    });

    test('a connected engine is live', () {
      expect(_linkOf(), const FreeModeLive());
    });

    test('a lost connection carries the age of the last data', () {
      final link = _linkOf(
        connection: const Disconnected(),
        lastDataAt: _now.subtract(const Duration(minutes: 1, seconds: 12)),
        now: _now,
      );

      expect(
        link,
        const FreeModeLost(dataAge: Duration(minutes: 1, seconds: 12)),
      );
    });

    test('a connection error is a lost connection too', () {
      final link = _linkOf(
        connection: const ConnectionError('reset'),
        lastDataAt: _now.subtract(const Duration(seconds: 5)),
        now: _now,
      );

      expect(link, const FreeModeLost(dataAge: Duration(seconds: 5)));
    });

    test('the age is unknown without data in this session', () {
      expect(
        _linkOf(connection: const Disconnected(), now: _now),
        const FreeModeLost(),
      );
    });

    test('the age is unknown before the first tick', () {
      expect(
        _linkOf(connection: const Disconnected(), lastDataAt: _now),
        const FreeModeLost(),
      );
    });

    test('a clock skew never gives a negative age', () {
      final link = _linkOf(
        connection: const Disconnected(),
        lastDataAt: _now.add(const Duration(seconds: 3)),
        now: _now,
      );

      expect(link, const FreeModeLost(dataAge: Duration.zero));
    });
  });
}
