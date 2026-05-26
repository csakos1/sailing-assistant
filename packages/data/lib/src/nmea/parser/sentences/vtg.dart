import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea_units.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

/// A `VTG` (course/speed over ground) mondatot `DecodedCogSog`-gá alakítja.
///
/// Mezők: `<cogTrue>,T,<cogMag>,M,<sogKn>,N,<sogKmh>,K,<mode>`. A v1 a true
/// COG-ot (field 0, trueNorth) és a csomóból m/s-ra váltott SOG-ot (field 4)
/// veszi; a mágneses COG és a km/h-érték redundáns (ARCHITECTURE.md 6.3).
///
/// `null`-t ad (skip), ha a szerkezet nem stimmel (rossz `T`/`N`
/// egységjelölő), egy mező csonka/nem-numerikus, vagy egy value object
/// validáció elbukik (A1 skip-szemantika).
class VtgCogSogDecoder {
  /// Állapotmentes dekóder; a default ctor const.
  const VtgCogSogDecoder();

  /// A [sentence]-ből `DecodedCogSog`, vagy `null` ha nem használható
  /// (lásd az osztály-doc skip-feltételeit).
  DecodedCogSog? decode(Sentence sentence) {
    final fields = sentence.fields;
    // VTG: cogTrue, T, cogMag, M, sogKnots, N, sogKmh, K, mode — kilenc mező.
    if (fields.length < 9) {
      return null;
    }

    // Egységjelölők: a true COG a [0]-n (T az [1]-en), a csomó-SOG a [4]-en
    // (N az [5]-en). Ezt a kettőt használjuk, így ezeket ellenőrizzük.
    if (fields[1] != 'T' || fields[5] != 'N') {
      return null;
    }

    final rawCog = double.tryParse(fields[0]);
    final rawSog = double.tryParse(fields[4]);
    if (rawCog == null || rawSog == null) {
      return null;
    }

    // A tryFromX (untrusted) ágat használjuk, így NaN/±∞/tartományon-kívüli
    // érték → skip a domainbe szivárgás helyett.
    final courseOverGround = switch (Bearing.tryFromDegrees(
      degrees: rawCog,
      reference: BearingReference.trueNorth,
    )) {
      Ok(value: final b) => b,
      Err() => null,
    };
    final speedOverGround = switch (Speed.tryFromMetersPerSecond(
      metersPerSecond: metersPerSecondFromKnots(rawSog),
    )) {
      Ok(value: final s) => s,
      Err() => null,
    };
    if (courseOverGround == null || speedOverGround == null) {
      return null;
    }

    return DecodedCogSog(
      courseOverGround: courseOverGround,
      speedOverGround: speedOverGround,
    );
  }
}
