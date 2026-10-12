import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_detail/detail_action.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'Tihany',
    position: Coordinate(latitude: 46.9, longitude: 17.9),
  );
  // A teszt UTC-ben szamol, hogy a gep idozonaja ne szamitson.
  DateTime toUtc(DateTime instant) => instant.toUtc();
  final now = DateTime.utc(2026, 10, 12, 12);

  Race race({DateTime? at}) => Race.create(
    id: 'r1',
    name: 'Alfa',
    marks: const [mark],
    scheduledStartAt: at,
  );

  DetailAction? actionOf(Race race) =>
      detailActionOf(race: race, now: now, toLocal: toUtc);

  test('offers a manual start without a scheduled start', () {
    expect(actionOf(race()), const DetailStart());
  });

  test('shows the automatic start for a later start today', () {
    // ARRANGE
    final start = DateTime.utc(2026, 10, 12, 14);

    // ACT & ASSERT
    expect(actionOf(race(at: start)), DetailScheduledStart(start));
  });

  test('shows the automatic start for a start tomorrow', () {
    // ARRANGE
    final start = DateTime.utc(2026, 10, 13, 9);

    // ACT & ASSERT
    expect(actionOf(race(at: start)), DetailScheduledStart(start));
  });

  test('keeps the automatic start inside the late window', () {
    // ARRANGE - a rajtido elmult, de az engine meg visszamenoleg indit.
    final start = DateTime.utc(2026, 10, 12, 9, 0, 1);

    // ACT & ASSERT
    expect(actionOf(race(at: start)), DetailScheduledStart(start));
  });

  test('falls back to a manual start when the window has run out', () {
    // ARRANGE - pont a 3. oraban mar nem indul magatol.
    final start = DateTime.utc(2026, 10, 12, 9);

    // ACT & ASSERT
    expect(actionOf(race(at: start)), const DetailStart());
  });

  test('falls back to a manual start for a start on an earlier day', () {
    // ARRANGE - az ablakon belul van, de egy tegnapi versenyt a nap
    // versenye nem valaszt ki, igy az engine sem indit.
    final early = DateTime.utc(2026, 10, 13, 0, 30);
    final start = DateTime.utc(2026, 10, 12, 23, 30);

    // ACT
    final action = detailActionOf(
      race: race(at: start),
      now: early,
      toLocal: toUtc,
    );

    // ASSERT
    expect(action, const DetailStart());
  });

  test('offers the finish while the race runs', () {
    expect(actionOf(race().start(at: now)), const DetailFinish());
  });

  test('has no action for a finished race', () {
    expect(actionOf(race().start(at: now).finish(at: now)), isNull);
  });
}
