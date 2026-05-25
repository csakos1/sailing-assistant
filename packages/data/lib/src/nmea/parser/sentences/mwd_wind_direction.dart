import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

/// Az `MWD` (wind direction) mondatot `DecodedWindDirection`-ná alakítja.
///
/// Mezők: `<dirTrue>,T,<dirMag>,M,<spdKn>,N,<spdMs>,M`. A v1 a **valódi**
/// szélirányt (TWD, field 0, trueNorth) és a közvetlenül adott m/s
/// szélsebességet (field 6) veszi; a mágneses irány és a csomó-érték
/// redundáns (ARCHITECTURE.md 6.5).
///
/// `null`-t ad (skip), ha a szerkezet nem stimmel (rossz `T`/`M`
/// egységjelölő), vagy egy mező csonka/nem-numerikus (A1 skip-szemantika).
class MwdWindDirectionDecoder {
  /// Állapotmentes dekóder; a default ctor const.
  const MwdWindDirectionDecoder();

  /// A [sentence]-ből `DecodedWindDirection`, vagy `null` ha nem
  /// használható (lásd az osztály-doc skip-feltételeit).
  DecodedWindDirection? decode(Sentence sentence) {
    final fields = sentence.fields;
    // MWD: dirTrue, T, dirMag, M, spdKnots, N, spdMs, M — nyolc mező.
    if (fields.length < 8) {
      return null;
    }

    // Egységjelölők: a true irány a [0]-n (T a [1]-en), az m/s sebesség a
    // [6]-on (M a [7]-en). Ezt a kettőt használjuk, így ezeket ellenőrizzük.
    if (fields[1] != 'T' || fields[7] != 'M') {
      return null;
    }

    final rawDirection = double.tryParse(fields[0]);
    final rawSpeed = double.tryParse(fields[6]);
    if (rawDirection == null || rawSpeed == null) {
      return null;
    }

    // A tryFromX (untrusted) ágat használjuk, így NaN/±∞/tartományon-kívüli
    // érték → skip a domainbe szivárgás helyett.
    final direction = switch (Bearing.tryFromDegrees(
      degrees: rawDirection,
      reference: BearingReference.trueNorth,
    )) {
      Ok(value: final b) => b,
      Err() => null,
    };
    final speed = switch (Speed.tryFromMetersPerSecond(
      metersPerSecond: rawSpeed,
    )) {
      Ok(value: final s) => s,
      Err() => null,
    };
    if (direction == null || speed == null) {
      return null;
    }

    return DecodedWindDirection(direction: direction, speed: speed);
  }
}
