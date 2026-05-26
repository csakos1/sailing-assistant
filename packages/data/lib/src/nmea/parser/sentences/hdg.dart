import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

/// A `HDG` (heading, magnetic) mondatot `DecodedHeading`-gé alakítja.
///
/// Mezők (address után):
/// `<headingMag>,<deviation>,<devDir>,<variation>,<varDir>`. A v1 csak a
/// mágneses headinget veszi (field 0); a deviáció és a variáció v1-ben nem
/// kell — a true heading a WMM-deklinációval áll elő a domainben
/// (ARCHITECTURE.md 6.5).
///
/// `null`-t ad (skip), ha a heading-mező hiányzik/csonka/nem-numerikus,
/// vagy a `Bearing` validáció elbukik (A1 skip-szemantika).
class HdgHeadingDecoder {
  /// Állapotmentes dekóder; a default ctor const.
  const HdgHeadingDecoder();

  /// A [sentence]-ből `DecodedHeading`, vagy `null` ha nem használható
  /// (lásd az osztály-doc skip-feltételeit).
  DecodedHeading? decode(Sentence sentence) {
    final fields = sentence.fields;
    // Csak a [0] (mágneses heading) kell, így elég a meglétét ellenőrizni.
    if (fields.isEmpty) {
      return null;
    }

    final rawHeading = double.tryParse(fields[0]);
    if (rawHeading == null) {
      return null;
    }

    // tryFromDegrees (untrusted): NaN/±∞ → skip a domainbe szivárgás helyett
    // (a véges érték [0, 360)-ba normalizálódik).
    final heading = switch (Bearing.tryFromDegrees(
      degrees: rawHeading,
      reference: BearingReference.magneticNorth,
    )) {
      Ok(value: final b) => b,
      Err() => null,
    };
    if (heading == null) {
      return null;
    }

    return DecodedHeading(heading: heading);
  }
}
