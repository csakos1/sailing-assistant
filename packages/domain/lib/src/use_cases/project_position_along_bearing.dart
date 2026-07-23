import 'dart:math' as math;

import 'package:domain/src/_internal/angles.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:domain/src/value_objects/coordinate.dart';
import 'package:domain/src/value_objects/distance.dart';
import 'package:meta/meta.dart';

/// A geodézia direkt feladata: pont + irány + távolság → új pont.
///
/// A `CalculateDistanceToMark` (inverz feladat) párja, ugyanazon a gömbi
/// modellen és ugyanazzal a földsugárral. A kettő szándékosan egy
/// rétegben él: a `latlong2` `Distance.offset`-je nem használt, mert a
/// domain a gömbi geometriát sajátként hordozza (ADR 0037 A1-D1).
///
/// Első fogyasztója az élő biztonsági térkép COG-iránvektora, ami a hajó
/// pozícióját a haladási irány mentén a látható átlón túlra vetíti ki
/// (ADR 0037 D12) — a vágást a térkép végzi.
///
/// **Pure use case**: nincs állapot, idempotens.
///
/// **A bearing kötelezően true-north referenciájú** (A1-D3). A vetítés a
/// földrajzi északhoz mér; mágneses bearinggel a végpont a deklináció
/// szögével fordulna el, ráadásul csendben, mert az eredmény továbbra is
/// érvényes koordináta lenne.
///
/// **A visszaadott hosszúság ±180 fokra normált** (A1-D4). A képlet nyers
/// eredménye átlépheti a tartományt, a `Coordinate` alap-konstruktora
/// pedig nem validál — normalizálás nélkül a hiba nem itt bukna ki, hanem
/// a fogyasztónál.
///
/// **Edge case-ek.** Nulla távolságnál a szögtávolság is nulla, tehát a
/// visszaadott pont a bemeneti. A pólusokon a hosszúság matematikailag
/// határozatlan, de az `atan2` ott is véges értéket ad — a Balaton-skálán
/// ez az eset nem fordul elő.
@immutable
class ProjectPositionAlongBearing {
  /// Const ctor — a use case stateless, példány-egyenlőség nem releváns;
  /// const-elve egyetlen instance is elég.
  const ProjectPositionAlongBearing();

  /// A Föld átlagos sugara méterben (WGS84-átlag). Szándékosan azonos a
  /// `CalculateDistanceToMark` konstansával: a direkt és az inverz
  /// feladatnak ugyanazon a gömbön kell dolgoznia, különben az oda-vissza
  /// vetítés nem zárna.
  static const double _earthRadiusMeters = 6371000;

  /// A [from] pontból a [bearing] irányban [distance] távolságra fekvő
  /// pont. Részletek a class-doc-ban.
  Coordinate call({
    required Coordinate from,
    required Bearing bearing,
    required Distance distance,
  }) {
    assert(
      bearing.reference == BearingReference.trueNorth,
      'A vetítés a földrajzi északhoz mér, ezért trueNorth-referenciájú '
      'Bearing kell.',
    );

    final angularDistance = distance.meters / _earthRadiusMeters;
    final lat1 = degreesToRadians(from.latitude);
    final lon1 = degreesToRadians(from.longitude);
    final bearingRadians = degreesToRadians(bearing.degrees);

    final sinLat1 = math.sin(lat1);
    final cosLat1 = math.cos(lat1);
    final sinAngular = math.sin(angularDistance);
    final cosAngular = math.cos(angularDistance);
    final sinBearing = math.sin(bearingRadians);
    final cosBearing = math.cos(bearingRadians);

    final sinLat2 = sinLat1 * cosAngular + cosLat1 * sinAngular * cosBearing;
    final lat2 = math.asin(sinLat2);

    // A hosszúság-különbség atan2-alakja: a számláló a kelet-nyugati, a
    // nevező az észak-déli komponens. Az atan2 a négy negyedet is helyesen
    // választja, szemben az atan-nal.
    final deltaLonY = sinBearing * sinAngular * cosLat1;
    final deltaLonX = cosAngular - sinLat1 * sinLat2;
    final lon2 = lon1 + math.atan2(deltaLonY, deltaLonX);

    return Coordinate(
      latitude: radiansToDegrees(lat2),
      longitude: _normalisedLongitude(radiansToDegrees(lon2)),
    );
  }

  /// A hosszúságot a ±180 fokos tartományba hozza. A Dart `%` operátora a
  /// osztó előjelét veszi fel, ezért negatív bemenetre is helyes.
  static double _normalisedLongitude(double degrees) =>
      (degrees + 540) % 360 - 180;
}
