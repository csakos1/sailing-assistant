import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea_field_parsers.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

/// A `GGA` (GPS fix data) mondatot `DecodedPosition`-né alakítja.
///
/// Mezők (address után): `<utc>,<lat>,<N|S>,<lon>,<E|W>,<fixQuality>,...`.
/// A v1 csak a pozíciót veszi (field 1..4); az időt az RMC adja, a
/// műholdszám/HDOP/magasság v1-ben nem kell (ARCHITECTURE.md 6.3).
///
/// `null`-t ad (skip), ha nincs érvényes fix (`fixQuality == '0'`), egy
/// koordináta-mező csonka/nem-numerikus, vagy a `Coordinate` validáció
/// elbukik (A1 skip-szemantika).
class GgaPositionDecoder {
  /// Állapotmentes dekóder; a default ctor const.
  const GgaPositionDecoder();

  /// A [sentence]-ből `DecodedPosition`, vagy `null` ha nem használható
  /// (lásd az osztály-doc skip-feltételeit).
  DecodedPosition? decode(Sentence sentence) {
    final fields = sentence.fields;
    // GGA: utc, lat, N/S, lon, E/W, fixQuality, ... — a fixQuality-ig ([5]) kell.
    if (fields.length < 6) {
      return null;
    }

    // fixQuality '0' = nincs érvényes GPS-fix → skip.
    if (fields[5] == '0') {
      return null;
    }

    final latitude = decimalDegreesFromNmea(fields[1], fields[2]);
    final longitude = decimalDegreesFromNmea(fields[3], fields[4]);
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
