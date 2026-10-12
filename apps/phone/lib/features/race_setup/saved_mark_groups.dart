import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

/// A bója-könyvtár egy csoportja: egy forrás-verseny bójái (35c).
@immutable
class SavedMarkGroup {
  /// Egy csoport a forrás-verseny nevével és a bójáival.
  const SavedMarkGroup({required this.raceName, required this.marks});

  /// A forrás-verseny neve (a csoport fejléce).
  final String raceName;

  /// A csoport bójái a bemenet sorrendjében.
  final List<SavedMark> marks;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedMarkGroup &&
          other.raceName == raceName &&
          listEquals(other.marks, marks);

  @override
  int get hashCode => Object.hash(raceName, Object.hashAll(marks));
}

/// A könyvtár bójáit forrás-verseny szerint csoportosítja (35c).
///
/// A csoportok a forrás-verseny **első előfordulásának** sorrendjében
/// jönnek, a bóják a csoporton belül a bemenet sorrendjében. A könyvtár
/// stream-je `savedAt` szerint csökkenő, így a legutóbb mentett verseny
/// áll elöl, és a csoportosítás ezt nem forgatja fel.
List<SavedMarkGroup> groupSavedMarks(List<SavedMark> marks) {
  final byRace = <String, List<SavedMark>>{};
  for (final mark in marks) {
    (byRace[mark.sourceRaceName] ??= []).add(mark);
  }
  return [
    for (final entry in byRace.entries)
      SavedMarkGroup(raceName: entry.key, marks: entry.value),
  ];
}
