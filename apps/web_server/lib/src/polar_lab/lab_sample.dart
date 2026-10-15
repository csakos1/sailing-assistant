import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:web_server/src/polar/polar_race.dart';

/// Egy elemzésre kész polár-minta (`docs/PLAN.md` P.1): érvényes,
/// tüske-mentes, és a telemetriánál korrigált vízsebességű.
///
/// Az egységek a polár egységei: a szög a `|TWA|` fokban (0–180), a
/// sebességek csomóban. A [seconds] a minta súlya (a telefoné 1, a régi
/// YDVR-naplóé 10 másodperc).
@immutable
final class LabSample extends Equatable {
  /// Minta a [raceId] versenyből.
  const LabSample({
    required this.raceId,
    required this.season,
    required this.source,
    required this.absTwaDeg,
    required this.twsKnots,
    required this.stwKnots,
    required this.seconds,
  });

  /// A verseny azonosítója.
  final String raceId;

  /// A verseny napjának éve (Budapesti idő szerint).
  final int season;

  /// Honnan jött a minta.
  final PolarSampleSource source;

  /// A valós szélszög abszolút értéke, 0–180 fok.
  final double absTwaDeg;

  /// A valós szélsebesség csomóban.
  final double twsKnots;

  /// A (korrigált) vízsebesség csomóban.
  final double stwKnots;

  /// A minta súlya másodpercben.
  final int seconds;

  @override
  List<Object?> get props => [
    raceId,
    season,
    source,
    absTwaDeg,
    twsKnots,
    stwKnots,
    seconds,
  ];
}
