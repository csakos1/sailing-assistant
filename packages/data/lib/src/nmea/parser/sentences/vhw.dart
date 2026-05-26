import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea_units.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

/// A `VHW` (water speed and heading) mondatot `DecodedSpeed`-dé alakítja.
///
/// Mezők (address után): `<hdgTrue>,T,<hdgMag>,M,<stwKn>,N,<stwKmh>,K`. A v1
/// csak a vízhez viszonyított sebességet (STW, field 4, csomó) veszi; a
/// heading a HDG-ből jön, a km/h-érték redundáns (ARCHITECTURE.md 6.3).
///
/// `null`-t ad (skip), ha a csomó-egységjelölő nem `N`, az STW-mező
/// csonka/nem-numerikus, vagy a `Speed` validáció elbukik (A1
/// skip-szemantika).
class VhwSpeedDecoder {
  /// Állapotmentes dekóder; a default ctor const.
  const VhwSpeedDecoder();

  /// A [sentence]-ből `DecodedSpeed`, vagy `null` ha nem használható
  /// (lásd az osztály-doc skip-feltételeit).
  DecodedSpeed? decode(Sentence sentence) {
    final fields = sentence.fields;
    // VHW: hdgTrue, T, hdgMag, M, stwKnots, N, ... — a csomó-egységig ([5]) kell.
    if (fields.length < 6) {
      return null;
    }

    // A csomó-STW a [4]-en, az N-egységjelölő az [5]-en. Ezt a kettőt
    // használjuk, így ezt ellenőrizzük.
    if (fields[5] != 'N') {
      return null;
    }

    final rawStw = double.tryParse(fields[4]);
    if (rawStw == null) {
      return null;
    }

    // tryFromMetersPerSecond (untrusted): NaN/±∞/negatív → skip a domainbe
    // szivárgás helyett.
    final speedThroughWater = switch (Speed.tryFromMetersPerSecond(
      metersPerSecond: metersPerSecondFromKnots(rawStw),
    )) {
      Ok(value: final s) => s,
      Err() => null,
    };
    if (speedThroughWater == null) {
      return null;
    }

    return DecodedSpeed(speedThroughWater: speedThroughWater);
  }
}
