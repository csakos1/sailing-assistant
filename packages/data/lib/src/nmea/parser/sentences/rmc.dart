import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea_field_parsers.dart';
import 'package:data/src/nmea/parser/nmea_units.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

/// Az `RMC` (recommended minimum) mondatot kompozit `DecodedRmc`-vé alakítja.
///
/// Egyetlen mondat hozza a pozíciót, a COG/SOG-ot és a GPS-időt; a mapper
/// (6.4) bontja külön event-ekre. Mezők (address után):
/// `<utc>,<A|V>,<lat>,<N|S>,<lon>,<E|W>,<sog kn>,<cog true>,<date>,...`.
///
/// `null`-t ad (skip), ha a status invalid (`V`), bármelyik mező
/// csonka/nem-numerikus, vagy egy value object validáció elbukik (a
/// mód-mező az újabb NMEA-ban opcionális, csak a 0–8 indexek kellenek).
class RmcDecoder {
  /// Állapotmentes dekóder; a default ctor const.
  const RmcDecoder();

  /// A [sentence]-ből `DecodedRmc`, vagy `null` ha nem használható.
  DecodedRmc? decode(Sentence sentence) {
    final fields = sentence.fields;
    if (fields.length < 9) {
      return null;
    }

    // Csak a valid ('A') fixet dolgozzuk fel ('V' = navigation receiver
    // warning, érvénytelen pozíció).
    if (fields[1] != 'A') {
      return null;
    }

    final latitude = decimalDegreesFromNmea(fields[2], fields[3]);
    final longitude = decimalDegreesFromNmea(fields[4], fields[5]);
    if (latitude == null || longitude == null) {
      return null;
    }

    final rawSog = double.tryParse(fields[6]);
    final rawCog = double.tryParse(fields[7]);
    if (rawSog == null || rawCog == null) {
      return null;
    }

    final timestampUtc = utcDateTimeFromNmea(fields[8], fields[0]);
    if (timestampUtc == null) {
      return null;
    }

    // Minden untrusted érték a tryFromX ágon megy be: NaN/±∞/tartományon
    // kívüli érték → skip a domainbe szivárgás helyett.
    final position = switch (Coordinate.tryFromDegrees(
      latitude: latitude,
      longitude: longitude,
    )) {
      Ok(value: final c) => c,
      Err() => null,
    };
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
    if (position == null ||
        courseOverGround == null ||
        speedOverGround == null) {
      return null;
    }

    return DecodedRmc(
      position: position,
      courseOverGround: courseOverGround,
      speedOverGround: speedOverGround,
      timestampUtc: timestampUtc,
    );
  }
}
