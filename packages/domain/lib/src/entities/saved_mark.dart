import 'package:domain/src/value_objects/coordinate.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Egy korábban használt bója a bója-könyvtárban (ADR 0032).
///
/// Előfordulás-rekord, nem fizikai katalógus (ADR 0032 L2): ugyanaz a
/// bója egy másik versenyben külön [SavedMark]. A [sourceRaceName] a
/// forrás verseny neve provenance-ként — denormalizált címke, NEM
/// idegen kulcs, ezért túléli a verseny törlését és átnevezését is
/// (ADR 0032 L1). A [savedAt] a könyvtár-picker rendezéséhez kell
/// (legutóbbi elöl).
///
/// A dedup-kulcs (`name`, E7-pozíció, `sourceRaceName`) és az egész-E7
/// koordináta-tárolás a data rétegben él (ADR 0032 L4); a domain
/// előjeles tizedes-fokot tárol [Coordinate]-ban. Egy `SavedMark`-ot
/// egy már mentett `Mark` és a verseny neve alapján gyártunk.
///
/// Immutable, value-equality ([Equatable] alapon). Az invariánsokat
/// (`name`/`sourceRaceName` nem üres) a const konstruktor `assert`-jei
/// őrzik — már validált forrásból gyártjuk, ezért nincs `Result`-alapú
/// factory.
@immutable
class SavedMark extends Equatable {
  /// Új [SavedMark]-ot készít. Az invariánsokat assert ellenőrzi: sem
  /// a [name], sem a [sourceRaceName] nem üres string.
  const SavedMark({
    required this.name,
    required this.position,
    required this.sourceRaceName,
    required this.savedAt,
  }) : assert(name != '', 'A bója neve nem lehet üres.'),
       assert(sourceRaceName != '', 'A forrás verseny neve nem lehet üres.');

  /// A bója human-readable neve (pl. "VK", "Tihany"). Üres nem érvényes.
  final String name;

  /// A bója földrajzi pozíciója, előjeles tizedes-fokban.
  final Coordinate position;

  /// A forrás verseny neve provenance-ként (denormalizált címke, nem FK).
  final String sourceRaceName;

  /// A könyvtárba mentés időpontja — a picker ez szerint rendez
  /// (legutóbbi elöl).
  final DateTime savedAt;

  @override
  List<Object?> get props => [name, position, sourceRaceName, savedAt];

  @override
  bool? get stringify => true;
}
