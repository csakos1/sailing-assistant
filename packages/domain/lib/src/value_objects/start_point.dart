import 'package:domain/src/entities/mark.dart';
import 'package:domain/src/value_objects/coordinate.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Egy verseny rajthelye: az a pont, ahová az app rajt előtt rávezet
/// (ADR 0055 D1).
///
/// Szándékosan nem [Mark]: nincs pálya-sorszáma, nem kerülhető meg, és
/// nem kerül a bóják közé. A predikció számára egy csak memóriában élő
/// [Mark]-ká alakítható ([asGuidanceMark]).
///
/// Immutable, value-equality ([Equatable] alapon). A [name] nem üres;
/// ezt a const konstruktor `assert`-je őrzi, mert már validált forrásból
/// (űrlap, DB-sor) gyártjuk.
@immutable
class StartPoint extends Equatable {
  /// Új rajthely. A [name] nem lehet üres string.
  const StartPoint({required this.name, required this.position})
    : assert(name != '', 'A rajthely neve nem lehet üres.');

  /// A rávezetéskor használt [Mark] sorszáma.
  ///
  /// A [Mark] invariánsa (`sequence >= 1`) miatt 1, nem 0. A sorszám a
  /// rajthelynél nem pálya-sorrend: a rávezetett „bója" sosem kerül a
  /// `Race` bójái közé, sem a DB-be, sem az izolátum-határon át egy
  /// verseny részeként.
  static const int guidanceMarkSequence = 1;

  /// A rajthely human-readable neve (pl. „Füredi rajtvonal").
  final String name;

  /// A rajthely földrajzi pozíciója.
  final Coordinate position;

  /// A rajthely mint rávezetési cél, a predikció bemenetének alakjában.
  ///
  /// A visszaadott [Mark] csak memóriában él; körözési állapota nincs.
  Mark asGuidanceMark() => Mark(
    sequence: guidanceMarkSequence,
    name: name,
    position: position,
  );

  @override
  List<Object?> get props => [name, position];

  @override
  bool? get stringify => true;
}
