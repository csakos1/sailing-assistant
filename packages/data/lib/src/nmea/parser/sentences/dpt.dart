import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

/// A `DPT` (depth of water) mondatot `DecodedDepth`-dé alakítja.
///
/// Mezők (address után): `<méter>,<offset>,<maxRange>`. A v1 a mélység-mezőt
/// (field 0) veszi; az offsetet (field 1) **nem** olvassuk (ADR 0031 A1-D4 —
/// a rögzített dumpon mind a 19 326 sorban `0.0`), a max range pedig v1-ben
/// nem használt.
///
/// Ez a **fallback** forrás: a dumpon 19 326 mintából 100 hamis 2,0 m-t írt,
/// max. 26 mp-es sorozatokban (ADR 0031 Addendum 1). Megtartjuk, mert a
/// `DBT` elnémulása esetén a zajos mélység jobb a semmilyennél; a stream
/// szintjén viszont a mapper elnyomja, amíg friss `DBT` van (Addendum 2).
///
/// `null`-t ad (skip), ha a mélység-mező hiányzik/csonka/nem-numerikus, vagy
/// a `Depth` validáció elbukik (A1 skip-szemantika).
class DptDepthDecoder {
  /// Állapotmentes dekóder; a default ctor const.
  const DptDepthDecoder();

  /// A [sentence]-ből `DecodedDepth`, vagy `null` ha nem használható
  /// (lásd az osztály-doc skip-feltételeit).
  DecodedDepth? decode(Sentence sentence) {
    final fields = sentence.fields;
    // DPT: meters, offset, maxRange — csak a [0] kell.
    if (fields.isEmpty) {
      return null;
    }

    final rawMeters = double.tryParse(fields[0]);
    if (rawMeters == null) {
      return null;
    }

    // tryFromMeters (untrusted): NaN/±∞/negatív → skip a domainbe szivárgás
    // helyett.
    final depth = switch (Depth.tryFromMeters(meters: rawMeters)) {
      Ok(value: final d) => d,
      Err() => null,
    };
    if (depth == null) {
      return null;
    }

    return DecodedDepth(depth: depth, source: DepthSource.dpt);
  }
}
