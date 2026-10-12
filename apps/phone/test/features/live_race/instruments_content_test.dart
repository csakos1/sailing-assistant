import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/live_race/instruments_content.dart';

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

InstrumentsContent _content({
  Race? selected,
  RaceSnapshot? snapshot,
  List<Race> races = const [],
}) => instrumentsContentOf(
  selectedRace: selected,
  snapshot: snapshot,
  races: races,
);

void main() {
  group('racing', () {
    test('shows the race the engine is racing', () {
      // Arrange
      final race = _active('r1');

      // Act
      final result = _content(
        selected: race,
        snapshot: _snapshot(status: RaceStatus.active, raceId: 'r1'),
      );

      // Assert
      expect(result, InstrumentsRacing(race));
    });

    test('keeps the race view right after a manual start', () {
      // Arrange: the DB is active, the engine has not ticked since.
      final race = _active('r1');

      // Act
      final result = _content(
        selected: race,
        snapshot: _snapshot(status: RaceStatus.notStarted, raceId: 'r1'),
        races: [_race('r1')],
      );

      // Assert
      expect(result, InstrumentsRacing(race));
    });

    test('an engine racing an unknown race is free mode', () {
      expect(
        _content(
          selected: _active('r1'),
          snapshot: _snapshot(status: RaceStatus.active, raceId: 'r2'),
        ),
        const InstrumentsFreeMode(),
      );
    });

    test('an engine start not yet taken over shows the race', () {
      // Arrange: the engine started r1 on its own; the DB still has it as
      // not started, and nothing is selected.
      final race = _race('r1');

      // Act
      final result = _content(
        snapshot: _snapshot(status: RaceStatus.active, raceId: 'r1'),
        races: [race],
      );

      // Assert
      expect(result, InstrumentsRacing(race));
    });

    test('a stale selection does not hide the race the engine runs', () {
      // Arrange: a forgotten active r0 stays selected while the engine
      // races r1.
      final race = _active('r1');

      // Act
      final result = _content(
        selected: _active('r0'),
        snapshot: _snapshot(status: RaceStatus.active, raceId: 'r1'),
        races: [_active('r0'), race],
      );

      // Assert
      expect(result, InstrumentsRacing(race));
    });

    test('a finished selection after the finish is free mode', () {
      // Arrange: the selection stays on the finished race, the engine is
      // free again.
      final finished = _active('r1').finish(at: DateTime.utc(2026, 7, 30, 11));

      // Act & Assert
      expect(
        _content(selected: finished, snapshot: _snapshot()),
        const InstrumentsFreeMode(),
      );
    });
  });

  group('pre-start', () {
    test("shows the engine's race not yet started", () {
      // Arrange
      final race = _race('r1');

      // Act
      final result = _content(
        snapshot: _snapshot(status: RaceStatus.notStarted, raceId: 'r1'),
        races: [_race('r0'), race],
      );

      // Assert
      expect(result, InstrumentsPreStart(race));
    });

    test('takes the fresh copy from the race list', () {
      // Arrange: the selection is stale, the list has the edited race.
      final edited = _race('r1').copyWith(name: 'Uj nev');

      // Act
      final result = _content(
        selected: _race('r1'),
        snapshot: _snapshot(status: RaceStatus.notStarted, raceId: 'r1'),
        races: [edited],
      );

      // Assert
      expect(result, InstrumentsPreStart(edited));
    });

    test('a race missing from the list is free mode', () {
      expect(
        _content(
          snapshot: _snapshot(status: RaceStatus.notStarted, raceId: 'r9'),
          races: [_race('r1')],
        ),
        const InstrumentsFreeMode(),
      );
    });

    test('a race already started in the list is not pre-start', () {
      // Arrange: started in the DB, the engine still not; not selected.
      expect(
        _content(
          snapshot: _snapshot(status: RaceStatus.notStarted, raceId: 'r1'),
          races: [_active('r1')],
        ),
        const InstrumentsFreeMode(),
      );
    });
  });

  group('free mode', () {
    test('without a snapshot (stopped engine)', () {
      expect(
        _content(selected: _active('r1'), races: [_race('r1')]),
        const InstrumentsFreeMode(),
      );
    });

    test('without a race in the engine', () {
      expect(
        _content(selected: _active('r1'), snapshot: _snapshot()),
        const InstrumentsFreeMode(),
      );
    });

    test('the tick that closes the race is free mode', () {
      // Arrange: the engine finished at the last mark itself.
      expect(
        _content(
          selected: _active('r1'),
          snapshot: _snapshot(status: RaceStatus.finished, raceId: 'r1'),
          races: [_active('r1')],
        ),
        const InstrumentsFreeMode(),
      );
    });
  });
}
