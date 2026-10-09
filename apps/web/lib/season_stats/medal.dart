import 'package:race_archive_api/race_archive_api.dart';

/// A dobogós helyezés érme a Statisztika-képernyőn (ADR 0049 Addendum 2
/// R5). A sorrend a jobbtól a rosszabb felé halad.
enum Medal {
  /// Első hely.
  gold,

  /// Második hely.
  silver,

  /// Harmadik hely.
  bronze
  ;

  /// A [placing] érme; `null`, ha nem dobogós vagy nincs megadva.
  static Medal? of(Placing? placing) => switch (placing) {
    FinishPlace(place: 1) => gold,
    FinishPlace(place: 2) => silver,
    FinishPlace(place: 3) => bronze,
    _ => null,
  };
}
