import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_setup/saved_mark_groups.dart';

void main() {
  SavedMark mark(String name, String race, int day) => SavedMark(
    name: name,
    position: const Coordinate(latitude: 46.9, longitude: 17.9),
    sourceRaceName: race,
    savedAt: DateTime.utc(2026, 6, day),
  );

  test('az ures konyvtar ures csoport-listat ad', () {
    // ACT & ASSERT
    expect(groupSavedMarks(const []), isEmpty);
  });

  test('versenyenkent csoportosit az elso elofordulas sorrendjeben', () {
    // ARRANGE - a stream savedAt szerint csokkeno; a Kedd esti ket
    // bojaja kozott egy masik verseny bojaja all.
    final tihany = mark('Tihany', 'Kedd esti', 9);
    final szemes = mark('Szemes', 'Lelle', 8);
    final cel = mark('Cel', 'Kedd esti', 7);

    // ACT
    final groups = groupSavedMarks([tihany, szemes, cel]);

    // ASSERT - a Kedd esti elol marad, mindket bojaja egy csoportban.
    expect(groups, [
      SavedMarkGroup(raceName: 'Kedd esti', marks: [tihany, cel]),
      SavedMarkGroup(raceName: 'Lelle', marks: [szemes]),
    ]);
  });

  test('a csoporton beluli sorrend a bemenete', () {
    // ARRANGE
    final a = mark('A', 'V', 3);
    final b = mark('B', 'V', 5);

    // ACT
    final groups = groupSavedMarks([a, b]);

    // ASSERT - nem rendez at, a hivo sorrendje ervenyes.
    expect(groups.single.marks, [a, b]);
  });
}
