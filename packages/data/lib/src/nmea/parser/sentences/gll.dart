import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea_field_parsers.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

/// A `GLL` (geographic position, lat/lon) mondatot `DecodedPosition`-né
/// alakítja.
///
/// Mezők (address után): `<lat>,<N|S>,<lon>,<E|W>,<utc>,<status>,...`. A
/// v1 csak a pozíciót veszi (field 0..3); az időt az RMC adja, a mód-jelző
/// v1-ben nem kell (ARCHITECTURE.md 6.3). Ugyanazt a `DecodedPosition`
/// leaf-et tölti, mint a GGA, de külön dekóderrel (minden mondat-dekóder
/// külön feat).
///
/// `null`-t ad (skip), ha a status invalid (`V`), egy koordináta-mező
/// csonka/nem-numerikus, vagy a `Coordinate` validáció elbukik (A1
/// skip-szemantika).
class GllPositionDecoder {
  /// Állapotmentes dekóder; a default ctor const.
  const GllPositionDecoder();

  /// A [sentence]-ből `DecodedPosition`, vagy `null` ha nem használható
  /// (lásd az osztály-doc skip-feltételeit).
  DecodedPosition? decode(Sentence sentence) {
    final fields = sentence.fields;
    // GLL: lat, N/S, lon, E/W, utc, status, ... — a status-ig ([5]) kell.
    if (fields.length < 6) {
      return null;
    }

    // status 'V' = navigation receiver warning, érvénytelen pozíció → skip.
    if (fields[5] == 'V') {
      return null;
    }

    final latitude = decimalDegreesFromNmea(fields[0], fields[1]);
    final longitude = decimalDegreesFromNmea(fields[2], fields[3]);
    if (latitude == null || longitude == null) {
      return null;
    }

    // tryFromDegrees (untrusted): tartományon kívüli / NaN → skip a domainbe
    // szivárgás helyett.
    final position = switch (Coordinate.tryFromDegrees(
      latitude: latitude,
      longitude: longitude,
    )) {
      Ok(value: final c) => c,
      Err() => null,
    };
    if (position == null) {
      return null;
    }

    return DecodedPosition(position: position);
  }
}
