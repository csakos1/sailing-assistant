import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

/// A `DBT` (depth below transducer) mondatot `DecodedDepth`-dé alakítja.
///
/// Mezők (address után): `<láb>,f,<méter>,M,<öl>,F`. A v1 a méter-mezőt
/// (field 2) veszi, az `M` egységjelölővel (field 3) ellenőrizve; a láb- és
/// öl-érték redundáns. A `DBT` fogalmilag a jeladó alatti mélységet adja,
/// offset-mező nélkül (ARCHITECTURE.md 6.1, ADR 0031 D2).
///
/// Ez az **elsődleges** mélység-forrás: a rögzített Vulcan-dumpon a 19 327
/// mintából egyetlen 0,5 m-nél nagyobb szomszédos ugrás sem volt, míg a
/// `DPT`-ben 58 (ADR 0031 Addendum 1).
///
/// `null`-t ad (skip), ha az egységjelölő nem `M`, a méter-mező
/// csonka/nem-numerikus, vagy a `Depth` validáció elbukik (A1
/// skip-szemantika).
class DbtDepthDecoder {
  /// Állapotmentes dekóder; a default ctor const.
  const DbtDepthDecoder();

  /// A [sentence]-ből `DecodedDepth`, vagy `null` ha nem használható
  /// (lásd az osztály-doc skip-feltételeit).
  DecodedDepth? decode(Sentence sentence) {
    final fields = sentence.fields;
    // DBT: feet, f, meters, M, ... — a méter-egységjelölőig ([3]) kell.
    if (fields.length < 4) {
      return null;
    }

    // A méter-mélység a [2]-n, az M-egységjelölő a [3]-on. Ezt a kettőt
    // használjuk, így ezt ellenőrizzük.
    if (fields[3] != 'M') {
      return null;
    }

    final rawMeters = double.tryParse(fields[2]);
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

    return DecodedDepth(depth: depth, source: DepthSource.dbt);
  }
}
