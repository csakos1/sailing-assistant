import 'package:domain/domain.dart';
import 'package:test/test.dart';

// Budapest wall clock for 2026 without depending on the machine's time
// zone: CEST (UTC+2) between 2026-03-29 01:00 UTC and 2026-10-25 01:00 UTC,
// CET (UTC+1) otherwise.
DateTime budapestWallClock(DateTime instant) {
  final utc = instant.toUtc();
  final summerStart = DateTime.utc(2026, 3, 29, 1);
  final summerEnd = DateTime.utc(2026, 10, 25, 1);
  final isSummer = !utc.isBefore(summerStart) && utc.isBefore(summerEnd);
  return utc.add(Duration(hours: isSummer ? 2 : 1));
}

void main() {
  const select = SelectInstrumentsRace();
  const mark = Mark(
    sequence: 1,
    name: 'A',
    position: Coordinate(latitude: 46.9, longitude: 18),
  );

  Race scheduled(String id, DateTime? at) => Race.create(
    id: id,
    name: 'Verseny $id',
    marks: const [mark],
    scheduledStartAt: at,
  );

  Race? run(
    List<Race> races, {
    required DateTime now,
    DateTime? lastRecordedAt,
    InstrumentsRaceChoice? choice,
    SelectInstrumentsRace use = select,
  }) => use(
    races: races,
    now: now,
    toLocal: budapestWallClock,
    activeRaceLastRecordedAt: lastRecordedAt,
    manualChoice: choice,
  );

  // 2026-07-30 09:00 Budapest (CEST).
  final nineLocal = DateTime.utc(2026, 7, 30, 7);
  final morning = DateTime.utc(2026, 7, 30, 5);

  group('free mode', () {
    test('no races means free mode', () {
      expect(run(const [], now: morning), isNull);
    });

    test('a race without a scheduled start is never chosen', () {
      // Arrange
      final races = [scheduled('r1', null)];

      // Act & Assert
      expect(run(races, now: morning), isNull);
    });

    test("yesterday's and tomorrow's races are not chosen", () {
      // Arrange
      final races = [
        scheduled('yesterday', nineLocal.subtract(const Duration(days: 1))),
        scheduled('tomorrow', nineLocal.add(const Duration(days: 1))),
      ];

      // Act & Assert
      expect(run(races, now: morning), isNull);
    });

    test('a started or finished race is not a scheduled candidate', () {
      // Arrange
      final finished = scheduled('done', nineLocal)
          .start(at: nineLocal)
          .finish(at: nineLocal.add(const Duration(hours: 1)));

      // Act & Assert
      expect(run([finished], now: morning), isNull);
    });
  });

  group("today's scheduled race", () {
    test('is chosen before its start', () {
      // Arrange
      final race = scheduled('r1', nineLocal);

      // Act & Assert
      expect(run([race], now: morning), race);
    });

    test('is still chosen just inside the late start window', () {
      // Arrange
      final race = scheduled('r1', nineLocal);
      final now = nineLocal
          .add(SelectInstrumentsRace.defaultLateStartWindow)
          .subtract(const Duration(seconds: 1));

      // Act & Assert
      expect(run([race], now: now), race);
    });

    test('is no longer chosen when the window has passed', () {
      // Arrange
      final race = scheduled('r1', nineLocal);
      final now = nineLocal.add(SelectInstrumentsRace.defaultLateStartWindow);

      // Act & Assert
      expect(run([race], now: now), isNull);
    });

    test('a custom window is honoured', () {
      // Arrange
      final race = scheduled('r1', nineLocal);
      const shortWindow = SelectInstrumentsRace(
        lateStartWindow: Duration(minutes: 30),
      );

      // Act
      final result = run(
        [race],
        now: nineLocal.add(const Duration(minutes: 30)),
        use: shortWindow,
      );

      // Assert
      expect(result, isNull);
    });

    test('the earliest of several races is chosen', () {
      // Arrange
      final early = scheduled('early', nineLocal);
      final later = scheduled('late', nineLocal.add(const Duration(hours: 2)));

      // Act & Assert
      expect(run([later, early], now: morning), early);
    });

    test('on equal start times the list order decides', () {
      // Arrange
      final first = scheduled('first', nineLocal);
      final second = scheduled('second', nineLocal);

      // Act & Assert
      expect(run([first, second], now: morning), first);
    });

    test('an expired race gives way to a later one the same day', () {
      // Arrange
      final early = scheduled('early', nineLocal);
      final later = scheduled('late', nineLocal.add(const Duration(hours: 4)));
      final now = nineLocal.add(const Duration(hours: 3, minutes: 10));

      // Act & Assert
      expect(run([early, later], now: now), later);
    });
  });

  group('manual choice', () {
    final early = scheduled('early', nineLocal);
    final later = scheduled('late', nineLocal.add(const Duration(hours: 2)));

    test("today's choice wins over the earliest race", () {
      // Arrange
      final choice = InstrumentsRaceChoice(
        raceId: 'late',
        chosenOnLocalDay: DateTime(2026, 7, 30),
      );

      // Act & Assert
      expect(run([early, later], now: morning, choice: choice), later);
    });

    test("yesterday's choice is ignored", () {
      // Arrange
      final choice = InstrumentsRaceChoice(
        raceId: 'late',
        chosenOnLocalDay: DateTime(2026, 7, 29),
      );

      // Act & Assert
      expect(run([early, later], now: morning, choice: choice), early);
    });

    test('a choice of an expired race gives way to a live one', () {
      // Arrange
      final afternoon = scheduled(
        'afternoon',
        nineLocal.add(const Duration(hours: 5)),
      );
      final choice = InstrumentsRaceChoice(
        raceId: 'early',
        chosenOnLocalDay: DateTime(2026, 7, 30),
      );
      final now = nineLocal.add(const Duration(hours: 3, minutes: 30));

      // Act
      final result = run(
        [early, later, afternoon],
        now: now,
        choice: choice,
      );

      // Assert: the 09:00Z race is still inside its window.
      expect(result, later);
    });

    test('a choice of a race that is not a candidate is ignored', () {
      // Arrange
      final dateless = scheduled('dateless', null);
      final choice = InstrumentsRaceChoice(
        raceId: 'dateless',
        chosenOnLocalDay: DateTime(2026, 7, 30),
      );

      // Act
      final result = run([dateless, early], now: morning, choice: choice);

      // Assert
      expect(result, early);
    });
  });

  group('active race', () {
    final startedAt = DateTime.utc(2026, 7, 29, 7);
    final active = scheduled('active', startedAt).start(at: startedAt);

    test('a resumable active race wins over a scheduled one', () {
      // Arrange: the two-day race recorded a minute ago.
      final today = scheduled('today', nineLocal);

      // Act
      final result = run(
        [today, active],
        now: morning,
        lastRecordedAt: morning.subtract(const Duration(minutes: 1)),
      );

      // Assert
      expect(result, active);
    });

    test('a forgotten finish gives way to the scheduled race', () {
      // Arrange: the last recording was yesterday afternoon.
      final today = scheduled('today', nineLocal);

      // Act
      final result = run(
        [active, today],
        now: morning,
        lastRecordedAt: DateTime.utc(2026, 7, 29, 14),
      );

      // Assert
      expect(result, today);
    });

    test('a forgotten finish without a scheduled race means free mode', () {
      // Act
      final result = run(
        [active],
        now: morning,
        lastRecordedAt: DateTime.utc(2026, 7, 29, 14),
      );

      // Assert
      expect(result, isNull);
    });

    test('a race started an hour ago without a recording resumes', () {
      // Arrange
      final justStarted = scheduled('fresh', null).start(at: morning);

      // Act
      final result = run(
        [justStarted],
        now: morning.add(const Duration(hours: 1)),
      );

      // Assert
      expect(result, justStarted);
    });

    test('of two active races the later started one counts', () {
      // Arrange
      final older = scheduled('older', null).start(at: startedAt);
      final newer = scheduled('newer', null).start(at: morning);

      // Act
      final result = run(
        [older, newer],
        now: morning.add(const Duration(minutes: 10)),
      );

      // Assert
      expect(result, newer);
      expect(SelectInstrumentsRace.latestActiveRace([older, newer]), newer);
    });

    test('a manual choice does not override a resumable active race', () {
      // Arrange
      final today = scheduled('today', nineLocal);
      final choice = InstrumentsRaceChoice(
        raceId: 'today',
        chosenOnLocalDay: DateTime(2026, 7, 30),
      );

      // Act
      final result = run(
        [today, active],
        now: morning,
        lastRecordedAt: morning.subtract(const Duration(minutes: 1)),
        choice: choice,
      );

      // Assert
      expect(result, active);
    });

    test('a stale active race scheduled for today is not a candidate', () {
      // Arrange: scheduled for 09:00 local today but started at 02:00
      // local, with nothing recorded since. At 09:30 local it is inside the
      // late start window, yet not resumable (7.5 h gap): only its status
      // keeps it from being a candidate.
      final stale = scheduled(
        'stale',
        nineLocal,
      ).start(at: DateTime.utc(2026, 7, 30));

      // Act
      final result = run(
        [stale],
        now: nineLocal.add(const Duration(minutes: 30)),
      );

      // Assert
      expect(result, isNull);
    });

    test('a custom resumable rule is honoured', () {
      // Arrange
      const strict = SelectInstrumentsRace(
        isRaceResumable: IsRaceResumable(maximumGap: Duration(minutes: 5)),
      );
      final justStarted = scheduled('fresh', null).start(at: morning);

      // Act
      final result = run(
        [justStarted],
        now: morning.add(const Duration(minutes: 10)),
        use: strict,
      );

      // Assert
      expect(result, isNull);
    });
  });

  group('local day boundaries', () {
    test('a 00:30 local start counts as today right after local midnight', () {
      // Arrange: 2026-07-30 22:30 UTC is 00:30 on 2026-07-31 in Budapest,
      // a different calendar day than in UTC.
      final race = scheduled('night', DateTime.utc(2026, 7, 30, 22, 30));

      // Act: 2026-07-30 22:05 UTC is 00:05 on 2026-07-31 in Budapest.
      final result = run([race], now: DateTime.utc(2026, 7, 30, 22, 5));

      // Assert
      expect(result, race);
    });

    test('a 23:30 local start is not chosen after midnight', () {
      // Arrange: 23:30 on 2026-07-30 in Budapest.
      final race = scheduled('late', DateTime.utc(2026, 7, 30, 21, 30));

      // Act: 00:15 on 2026-07-31, inside the window but another day.
      final result = run([race], now: DateTime.utc(2026, 7, 30, 22, 15));

      // Assert
      expect(result, isNull);
    });

    test('the DST change day is one local day', () {
      // Arrange: 10:00 CET on 2026-10-25 (the clocks went back at 03:00).
      final race = scheduled('dst', DateTime.utc(2026, 10, 25, 9));

      // Act: 00:30 CEST on 2026-10-25, before the change.
      final result = run([race], now: DateTime.utc(2026, 10, 24, 22, 30));

      // Assert
      expect(result, race);
    });

    test('each instant is localised with its own offset', () {
      // Arrange: 00:30 CEST on 2026-10-25, before the clocks go back.
      final race = scheduled('dst', DateTime.utc(2026, 10, 24, 22, 30));

      // Act: 02:10 CET on 2026-10-25, after the change, inside the window.
      // With the CET offset applied to both, the start would fall on
      // 2026-10-24 and the race would be missed.
      final result = run([race], now: DateTime.utc(2026, 10, 25, 1, 10));

      // Assert
      expect(result, race);
    });

    test('the spring change day is one local day', () {
      // Arrange: 10:00 CEST on 2026-03-29 (the clocks went forward).
      final race = scheduled('spring', DateTime.utc(2026, 3, 29, 8));

      // Act: 00:30 CET on 2026-03-29, before the change.
      final result = run([race], now: DateTime.utc(2026, 3, 28, 23, 30));

      // Assert
      expect(result, race);
    });

    test('the evening before the DST change is another day', () {
      // Arrange
      final race = scheduled('dst', DateTime.utc(2026, 10, 25, 9));

      // Act: 23:30 CEST on 2026-10-24.
      final result = run([race], now: DateTime.utc(2026, 10, 24, 21, 30));

      // Assert
      expect(result, isNull);
    });
  });
}
