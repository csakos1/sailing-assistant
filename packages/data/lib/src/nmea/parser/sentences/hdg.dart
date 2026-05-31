import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

/// A `HDG` (heading, magnetic) mondatot `DecodedHeading`-gé alakítja.
///
/// Mezők (address után):
/// `<headingMag>,<deviation>,<devDir>,<variation>,<varDir>`. A v1 a mágneses
/// headinget (field 0) veszi, és — ha a variáció ([3] érték + [4] E/W) jelen
/// van — a true headinget is előállítja (`true = magnetic + variation`,
/// E → +, W → −; ADR 0013). A Vulcan a variációt minden HDG-ben adja, így a
/// chartplotterrel konzisztens; a teljes WMM-modell v2-fallback. A deviáció
/// ([1]/[2]) v1-ben nem kell.
///
/// `null`-t ad (skip), ha a heading-mező hiányzik/csonka/nem-numerikus, vagy
/// a `Bearing` validáció elbukik (A1 skip-szemantika). A variáció hiánya vagy
/// csonkasága NEM skip — csak a `headingTrue` lesz `null`.
class HdgHeadingDecoder {
  /// Állapotmentes dekóder; a default ctor const.
  const HdgHeadingDecoder();

  /// A [sentence]-ből `DecodedHeading`, vagy `null` ha nem használható
  /// (lásd az osztály-doc skip-feltételeit).
  DecodedHeading? decode(Sentence sentence) {
    final fields = sentence.fields;
    // A [0] (mágneses heading) kötelező; a variáció ([3]+[4]) opcionális.
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

    return DecodedHeading(
      heading: heading,
      headingTrue: _trueHeading(heading, fields),
    );
  }

  // A mágneses headingből a műszer-variációval (HDG [3] érték + [4] E/W)
  // true headinget számol; `null`, ha a variáció hiányzik vagy nem
  // értelmezhető (graceful, ADR 0013 D3). E → kelet (+), W → nyugat (−).
  Bearing? _trueHeading(Bearing magnetic, List<String> fields) {
    if (fields.length <= 4) {
      return null;
    }
    final magnitude = double.tryParse(fields[3]);
    if (magnitude == null || !magnitude.isFinite || magnitude < 0) {
      return null;
    }
    final signed = switch (fields[4]) {
      'E' => magnitude,
      'W' => -magnitude,
      _ => null,
    };
    if (signed == null) {
      return null;
    }
    return switch (Bearing.tryFromDegrees(
      degrees: magnetic.degrees + signed,
      reference: BearingReference.trueNorth,
    )) {
      Ok(value: final b) => b,
      Err() => null,
    };
  }
}
