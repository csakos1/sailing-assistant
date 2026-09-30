import 'package:domain/domain.dart';

// Kozos tesztfixturak. A Race-t a publikus state-machine-en at epitjuk
// (create -> start -> round -> finish), hogy az invarians biztosan
// teljesuljon. Minden idopont UTC: a DateTime == az isUtc flaget is
// osszeveti, a dekoder pedig UTC-t ad vissza.

final DateTime raceStart = DateTime.utc(2026, 7, 18, 9);
final DateTime firstRounding = DateTime.utc(2026, 7, 18, 10, 12, 30);
final DateTime raceFinish = DateTime.utc(2026, 7, 18, 13, 45);

const Mark tihanyMark = Mark(
  sequence: 1,
  name: 'Tihany',
  position: Coordinate(latitude: 46.9125, longitude: 17.8890),
);

const Mark fureduMark = Mark(
  sequence: 2,
  name: 'Fured',
  position: Coordinate(latitude: 46.9502, longitude: 17.8931),
);

/// Befejezett verseny ket bojaval, az elso megkerulve.
Race finishedRace({String id = 'race-1', String name = 'Kekszalag'}) {
  final active = Race.create(
    id: id,
    name: name,
    marks: const [tihanyMark, fureduMark],
  ).start(at: raceStart);
  return active.roundCurrentMark(at: firstRounding).finish(at: raceFinish);
}
