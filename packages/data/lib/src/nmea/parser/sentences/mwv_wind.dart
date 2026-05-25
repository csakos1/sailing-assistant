import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea_units.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

/// Az `MWV` (wind speed/angle) mondatot `DecodedWind`-dé alakítja.
///
/// Mezők: `<angle>,<R|T>,<speed>,<N|K|M>,<A|V>`. A referencia `R`=apparent
/// vagy `T`=true; a sebesség-egység `N`=csomó / `K`=km/h / `M`=m/s. A
/// dekóder a wire-egységet a domain SI-jára (m/s) váltja — a `Speed` m/s-ban
/// tárol (a csomó-megjelenítés a presentation rétegé).
///
/// `null`-t ad (skip), ha a `status` invalid (`V`), az egység/referencia
/// ismeretlen, vagy egy mező csonka/nem-numerikus (ARCHITECTURE.md 6.3,
/// A1 skip-szemantika).
class MwvWindDecoder {
  /// Állapotmentes dekóder; a default ctor const.
  const MwvWindDecoder();

  /// A [sentence]-ből `DecodedWind`, vagy `null` ha a mondat nem
  /// használható (lásd az osztály-doc skip-feltételeit).
  DecodedWind? decode(Sentence sentence) {
    final fields = sentence.fields;
    // MWV: angle, reference, speed, unit, status — öt mező.
    if (fields.length < 5) {
      return null;
    }

    // Csak a valid ('A') status-flagű mondatot dolgozzuk fel.
    if (fields[4] != 'A') {
      return null;
    }

    final reference = switch (fields[1]) {
      'R' => WindReference.apparent,
      'T' => WindReference.true_,
      _ => null,
    };
    if (reference == null) {
      return null;
    }

    final rawAngle = double.tryParse(fields[0]);
    final rawSpeed = double.tryParse(fields[2]);
    if (rawAngle == null || rawSpeed == null) {
      return null;
    }

    final metersPerSecond = switch (fields[3]) {
      'N' => metersPerSecondFromKnots(rawSpeed),
      'K' => metersPerSecondFromKmh(rawSpeed),
      'M' => rawSpeed,
      _ => null,
    };
    if (metersPerSecond == null) {
      return null;
    }

    // A wire-szög 0–360 az orrtól; az Angle signed [-180, +180)-ba
    // normalize-zal. Mindkét value object a tryFromX (untrusted) ágat
    // használja, így NaN/±∞ → skip a domainbe szivárgás helyett.
    final angle = switch (Angle.tryFromDegrees(degrees: rawAngle)) {
      Ok(value: final a) => a,
      Err() => null,
    };
    final speed = switch (Speed.tryFromMetersPerSecond(
      metersPerSecond: metersPerSecond,
    )) {
      Ok(value: final s) => s,
      Err() => null,
    };
    if (angle == null || speed == null) {
      return null;
    }

    return DecodedWind(reference: reference, angle: angle, speed: speed);
  }
}
