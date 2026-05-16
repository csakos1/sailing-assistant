import 'dart:math' as math;

import 'package:domain/src/_internal/angles.dart';
import 'package:domain/src/value_objects/coordinate.dart';
import 'package:domain/src/value_objects/distance.dart';
import 'package:meta/meta.dart';

/// Két koordináta közötti gömbi távolság számítása haversine képlettel.
///
/// A haversine a great-circle distance robosztus képlete: numerikusan
/// stabil kis (méter) és nagy (több ezer km) távolságokon egyaránt,
/// szemben a "spherical law of cosines"-szel, ami kis távolságokon
/// floating-point pontatlanságot szenved (egymáshoz közeli `1 - cos(x)`
/// kivonás eltünteti az értelmes jegyeket).
///
/// Konstans földsugár: 6 371 000 m (WGS84 átlag). A Balatonon
/// (max ~80 km kiterjedés) az ellipszoid-vs-gömb modellkülönbség
/// elhanyagolható (sub-meter), és a navigációs használat pontossága
/// nem ezen múlik.
///
/// **Pure use case**: nincs állapot, idempotens. A [Distance]
/// non-negatív (haversine `c` mindig ≥ 0) és véges.
///
/// **Edge case-ek.** `from == to` esetén `a == 0`, `c == 0`, eredmény
/// `Distance(meters: 0)`. Antipodális pontoknál `a` elméletileg
/// pontosan 1, gyakorlatban floating-point hibából enyhén >1 lehet,
/// ami a `math.sqrt(1 - a)` ágban NaN-t okozhat — a Balaton-skálán
/// (max ~80 km) ez az eset nem fordulhat elő, és a 18.3-as fix bóya-CSV
/// validációja eleve kizárja.
@immutable
class CalculateDistanceToMark {
  /// Const ctor — a use case stateless, példány-egyenlőség nem
  /// releváns; const-elve egyetlen instance is elég.
  const CalculateDistanceToMark();

  /// A Föld átlagos sugara méterben (WGS84-átlag). A Balaton-skálán
  /// az egyenlítői (6 378 137 m) és sarki (6 356 752 m) sugár
  /// különbsége a great-circle számításban irreleváns.
  static const double _earthRadiusMeters = 6371000;

  /// Haversine távolság a [from] pontból a [to] pontba, méterben.
  /// Részletek a class-doc-ban.
  Distance call(Coordinate from, Coordinate to) {
    final lat1 = degreesToRadians(from.latitude);
    final lat2 = degreesToRadians(to.latitude);
    final dLat = degreesToRadians(to.latitude - from.latitude);
    final dLon = degreesToRadians(to.longitude - from.longitude);

    final sinHalfDLat = math.sin(dLat / 2);
    final sinHalfDLon = math.sin(dLon / 2);
    final a =
        sinHalfDLat * sinHalfDLat +
        math.cos(lat1) * math.cos(lat2) * sinHalfDLon * sinHalfDLon;
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return Distance(meters: _earthRadiusMeters * c);
  }
}
