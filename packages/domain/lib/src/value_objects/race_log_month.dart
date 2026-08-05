import 'package:domain/src/entities/race.dart';
import 'package:meta/meta.dart';

/// Egy naptári hónap befejezett versenyei a Versenynaplóban
/// (ADR 0044 D40).
///
/// Tiszta domain value object: a `BuildRaceLog` use case állítja elő, a
/// `finishedAt` **helyi idejű** hónapja szerint csoportosítva (D32). A
/// [races] lista a hónapon belül csökkenő időrendben áll.
///
/// A [month] puszta 1..12-es sorszám: a lokalizált hónapnév a
/// presentation-réteg dolga (D43), a domain nem ismer nyelvet.
///
/// Szándékosan nincs érték-egyenlősége: a szerkezetet egyetlen use case
/// állítja elő és a widget-réteg fogyasztja, a tesztek pedig mezőnként
/// állítanak — a mély lista-összehasonlítás csak zajt adna.
@immutable
class RaceLogMonth {
  /// A [races] listát módosíthatatlanná másoljuk, hogy a napló
  /// szerkezete a felépítés után kívülről se legyen állítható.
  RaceLogMonth({required this.month, required List<Race> races})
    : races = List.unmodifiable(races),
      assert(
        month >= 1 && month <= 12,
        'A hónap sorszáma 1 és 12 között lehet.',
      ),
      assert(races.isNotEmpty, 'Üres hónap nem kerül a naplóba.');

  /// A hónap sorszáma: 1 (január) .. 12 (december).
  final int month;

  /// A hónap versenyei befejezés szerint csökkenő sorrendben.
  final List<Race> races;

  /// A hónap verseny-darabszáma — a hónap-fejléc jobb oldalán jelenik
  /// meg.
  int get raceCount => races.length;

  @override
  String toString() => 'RaceLogMonth(month: $month, raceCount: $raceCount)';
}
