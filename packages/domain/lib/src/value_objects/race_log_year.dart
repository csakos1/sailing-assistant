import 'package:domain/src/value_objects/race_log_month.dart';
import 'package:meta/meta.dart';

/// Egy naptári év befejezett versenyei hónapokra bontva
/// (ADR 0044 D40).
///
/// Tiszta domain value object: a `BuildRaceLog` use case állítja elő. A
/// [months] lista csökkenő sorrendben áll (december elöl), és csak
/// olyan hónapokat tartalmaz, amelyekben volt befejezett verseny — üres
/// hónap nem kerül a naplóba.
///
/// A [RaceLogMonth]-hoz hasonlóan nincs érték-egyenlősége; az indoklás
/// ott áll.
@immutable
class RaceLogYear {
  /// A [months] listát módosíthatatlanná másoljuk, ahogy a hónap teszi
  /// a versenyeivel.
  RaceLogYear({required this.year, required List<RaceLogMonth> months})
    : months = List.unmodifiable(months),
      assert(months.isNotEmpty, 'Üres év nem kerül a naplóba.');

  /// Az év négyjegyű száma, helyi időzóna szerint.
  final int year;

  /// Az év hónapjai csökkenő sorrendben.
  final List<RaceLogMonth> months;

  /// Az év összes befejezett versenye — a képernyő-fejléc darabszáma és
  /// az összesítő stat-csík alapja.
  int get raceCount =>
      months.fold<int>(0, (sum, month) => sum + month.raceCount);

  @override
  String toString() => 'RaceLogYear(year: $year, raceCount: $raceCount)';
}
