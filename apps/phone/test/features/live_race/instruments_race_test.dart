import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/live_race/instruments_race.dart';

const _mark = Mark(
  sequence: 1,
  name: '1. boja',
  position: Coordinate(latitude: 46.9, longitude: 17.9),
);

Race _race(String id) =>
    Race.create(id: id, name: 'Kedd esti', marks: const [_mark]);

Race _active(String id) => _race(id).start(at: DateTime.utc(2026, 7, 30, 9));

RaceSnapshot _snapshot({RaceStatus? status, String? raceId}) => RaceSnapshot(
  eventCount: 10,
  boatState: BoatState(lastUpdate: DateTime.utc(2026, 7, 30, 9, 5)),
  connectionStatus: const Connected(),
  tickTime: DateTime.utc(2026, 7, 30, 9, 5),
  raceStatus: status,
  raceId: raceId,
);

void main() {
  group('instrumentsRaceOf', () {
    test('shows the race the engine is racing', () {
      final race = _active('r1');

      final result = instrumentsRaceOf(
        selectedRace: race,
        snapshot: _snapshot(status: RaceStatus.active, raceId: 'r1'),
      );

      expect(result, same(race));
    });

    test('free mode after the finish, while the selection stays', () {
      // A Cel utan a kivalasztas a befejezett versenyen marad, az engine
      // mar szabad modban fut.
      final finished = _active('r1').finish(at: DateTime.utc(2026, 7, 30, 11));

      final result = instrumentsRaceOf(
        selectedRace: finished,
        snapshot: _snapshot(),
      );

      expect(result, isNull);
    });

    test('free mode without a selected race', () {
      expect(
        instrumentsRaceOf(
          selectedRace: null,
          snapshot: _snapshot(status: RaceStatus.active, raceId: 'r1'),
        ),
        isNull,
      );
    });

    test('free mode without a snapshot (engine stopped)', () {
      expect(
        instrumentsRaceOf(selectedRace: _active('r1'), snapshot: null),
        isNull,
      );
    });

    test('free mode while the engine races another race', () {
      expect(
        instrumentsRaceOf(
          selectedRace: _active('r1'),
          snapshot: _snapshot(status: RaceStatus.active, raceId: 'r2'),
        ),
        isNull,
      );
    });

    test('free mode while the engine guides to a race before its start', () {
      // A rajt elotti tartalom (34b) az U4-e; addig a szabad mod.
      expect(
        instrumentsRaceOf(
          selectedRace: _race('r1'),
          snapshot: _snapshot(status: RaceStatus.notStarted, raceId: 'r1'),
        ),
        isNull,
      );
    });

    test('free mode right after a manual start, before the engine follows', () {
      expect(
        instrumentsRaceOf(selectedRace: _active('r1'), snapshot: _snapshot()),
        isNull,
      );
    });

    test('free mode when only the engine still races (finish in the UI)', () {
      final finished = _active('r1').finish(at: DateTime.utc(2026, 7, 30, 11));

      expect(
        instrumentsRaceOf(
          selectedRace: finished,
          snapshot: _snapshot(status: RaceStatus.active, raceId: 'r1'),
        ),
        isNull,
      );
    });
  });
}
