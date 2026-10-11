import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/shell/instruments_tab_status.dart';
import 'package:phone/providers/engine_session_state.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.9, longitude: 18.05),
  );
  final start = DateTime.utc(2026, 7, 30, 7);
  final planned = Race.create(
    id: 'r1',
    name: 'Kekszalag',
    marks: const [mark],
  ).copyWith(scheduledStartAt: start);
  final active = planned.start(at: start);
  const running = EngineRunning(cause: EngineStartCause.gatewayFound);
  // A teszt idozonatol fuggetlen: a „helyi" ido itt az UTC.
  DateTime toUtc(DateTime instant) => instant.toUtc();

  InstrumentsLink linkOf(EngineSessionState session, ConnectionStatus link) =>
      instrumentsTabStatusOf(
        session: session,
        connection: link,
        selectedRace: null,
        dayRace: null,
        toLocal: toUtc,
      ).link;

  group('the link edge', () {
    test('a stopped engine has no link, whatever the last snapshot said', () {
      expect(
        linkOf(const EngineStopped(), const Connected()),
        InstrumentsLink.disconnected,
      );
    });

    test('a probe is searching for the boat', () {
      expect(
        linkOf(const EngineProbing(), const Disconnected()),
        InstrumentsLink.searching,
      );
    });

    test('a running engine follows its snapshot', () {
      expect(linkOf(running, const Connected()), InstrumentsLink.connected);
      expect(linkOf(running, const Connecting()), InstrumentsLink.searching);
      expect(
        linkOf(running, const Disconnected()),
        InstrumentsLink.disconnected,
      );
      expect(
        linkOf(running, const ConnectionError('socket closed')),
        InstrumentsLink.disconnected,
      );
    });

    test('reconnecting after data is no link, not a search', () {
      final status = instrumentsTabStatusOf(
        session: running,
        connection: const Connecting(),
        selectedRace: null,
        dayRace: null,
        toLocal: toUtc,
        hasSessionData: true,
      );

      expect(status.link, InstrumentsLink.disconnected);
    });
  });

  group('the badge', () {
    test("shows the day race's start in local time before the race", () {
      // ACT
      final status = instrumentsTabStatusOf(
        session: running,
        connection: const Connected(),
        selectedRace: planned,
        dayRace: planned,
        toLocal: toUtc,
      );

      // ASSERT
      expect(status.scheduledStartAt, start.toUtc());
      expect(status.scheduledStartAt?.isUtc, isTrue);
      expect(status.isLive, isFalse);
    });

    test('an active race wins over the start time', () {
      // ACT
      final status = instrumentsTabStatusOf(
        session: running,
        connection: const Connected(),
        selectedRace: active,
        dayRace: planned,
        toLocal: toUtc,
      );

      // ASSERT
      expect(status.isLive, isTrue);
      expect(status.scheduledStartAt, isNull);
    });

    test('a finished race is not live', () {
      // ACT
      final status = instrumentsTabStatusOf(
        session: running,
        connection: const Connected(),
        selectedRace: active.finish(at: start.add(const Duration(hours: 1))),
        dayRace: null,
        toLocal: toUtc,
      );

      // ASSERT
      expect(status.isLive, isFalse);
      expect(status.scheduledStartAt, isNull);
    });
  });
}
