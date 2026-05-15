import 'package:domain/src/value_objects/coordinate.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Egy bója egy versenyen belül — sorszám, név, földrajzi pozíció és
/// (opcionálisan) körözés időbélyege.
///
/// Immutable, value-equality ([Equatable] alapon). A [sequence]
/// race-en belüli sorszám (1-től kezdve), a [name] human-readable
/// azonosító. A [roundedAt] null amíg a bója nincs körözve, után az
/// időpontot tárolja.
///
/// A körözés monoton: a [markedAsRounded] csak akkor hívható, ha a
/// bója még nincs körözve. Ez kódolja a domain-invariánst, hogy egy
/// bóya kétszer nem körözhető.
///
/// Az invariánsokat (`sequence >= 1`, `name.isNotEmpty`) a const
/// konstruktor `assert`-jei őrzik. Az entitásokat tipikusan már
/// validált forrásból (UI form, DB row) gyártjuk, ezért nem ad
/// `Result`-alapú factory-t — ha érvénytelen érték jön, az
/// programozói hiba.
@immutable
class Mark extends Equatable {
  /// Új Mark-ot készít. Az invariánsokat assert ellenőrzi: a
  /// [sequence] legalább 1, a [name] nem üres string.
  const Mark({
    required this.sequence,
    required this.name,
    required this.position,
    this.roundedAt,
  }) : assert(sequence >= 1, 'A bója sorszáma legalább 1.'),
       assert(name != '', 'A bója neve nem lehet üres.');

  /// Race-en belüli sorszám (1-től kezdve). A bóyák sorrendje a
  /// `Race.marks` listában az index szerint, a [sequence] a
  /// domain-szintű azonosító.
  final int sequence;

  /// Human-readable név (pl. "Tihany", "Z1", "Mark A"). Üres string
  /// nem érvényes.
  final String name;

  /// A bója földrajzi pozíciója.
  final Coordinate position;

  /// Körözés időpontja, vagy null ha még nincs körözve.
  final DateTime? roundedAt;

  /// Új Mark körözött állapotban. Csak akkor hívható, ha a bója még
  /// nincs körözve — a domain-invariánst (egy bója nem körözhető
  /// kétszer) assert védi.
  Mark markedAsRounded({required DateTime at}) {
    assert(roundedAt == null, 'A bója már körözve van.');
    return copyWith(roundedAt: at);
  }

  /// Új Mark a megadott mezők frissítésével. Simple-form copyWith:
  /// null érték "ne változtass" jelentéssel bír. Ez itt szándékos —
  /// a [roundedAt]-et ezzel nem lehet visszaállítani null-ra, ami
  /// kódolja az "egyszer körözve, mindig körözve" invariánst.
  Mark copyWith({
    int? sequence,
    String? name,
    Coordinate? position,
    DateTime? roundedAt,
  }) {
    return Mark(
      sequence: sequence ?? this.sequence,
      name: name ?? this.name,
      position: position ?? this.position,
      roundedAt: roundedAt ?? this.roundedAt,
    );
  }

  @override
  List<Object?> get props => [sequence, name, position, roundedAt];

  @override
  bool? get stringify => true;
}
