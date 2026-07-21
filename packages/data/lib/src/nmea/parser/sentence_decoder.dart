import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:data/src/nmea/parser/sentences/dbt.dart';
import 'package:data/src/nmea/parser/sentences/dpt.dart';
import 'package:data/src/nmea/parser/sentences/gga.dart';
import 'package:data/src/nmea/parser/sentences/gll.dart';
import 'package:data/src/nmea/parser/sentences/hdg.dart';
import 'package:data/src/nmea/parser/sentences/mwd_wind_direction.dart';
import 'package:data/src/nmea/parser/sentences/mwv_wind.dart';
import 'package:data/src/nmea/parser/sentences/rmc.dart';
import 'package:data/src/nmea/parser/sentences/vhw.dart';
import 'package:data/src/nmea/parser/sentences/vtg.dart';

/// Talker-agnosztikus mondat-dispatcher: a `Sentence.type` alapján a
/// megfelelő mondat-dekóderhez route-ol, és a dekódolt `DecodedSentence`-t
/// (vagy `null`-t) adja vissza.
///
/// Szándékosan **csak a `type`-ra** route-ol, NEM talker+type-ra: a valós
/// Vulcan dumpban ugyanaz a típus vegyes talkerrel jön (`GP`/`GN`/`II`/
/// `SD`/`WI`), így a talker beszámítása valid mondatokat dobna el
/// (ARCHITECTURE.md 6.3).
///
/// A `DBT` és a `DPT` ugyanannak a PGN 128267-nek két kiírása, ezért mindkettő
/// `DecodedDepth`-et ad, forrás-jelöléssel; a kettő közti választás **nem itt**
/// történik, hanem a mapperben (a dekóder állapotmentes, ADR 0031 Addendum 2).
///
/// `null`-t ad (skip), ha a `type` nem támogatott (pl. `GSV`, `ZDA`), vagy
/// ha a kiválasztott dekóder maga skippel (csonka/invalid mező vagy
/// status-flag) — a per-dekóder skip-szemantika változatlanul átöröklődik.
class SentenceDecoder {
  /// Állapotmentes dispatcher; a default ctor const.
  const SentenceDecoder();

  // A támogatott dekóderek statikus const regisztere. Mind állapotmentes,
  // ezért megosztott példányként tartható (a switch nem allokál).
  static const _mwvWind = MwvWindDecoder();
  static const _mwdWindDirection = MwdWindDirectionDecoder();
  static const _rmc = RmcDecoder();
  static const _vtgCogSog = VtgCogSogDecoder();
  static const _ggaPosition = GgaPositionDecoder();
  static const _gllPosition = GllPositionDecoder();
  static const _hdgHeading = HdgHeadingDecoder();
  static const _vhwSpeed = VhwSpeedDecoder();
  static const _dbtDepth = DbtDepthDecoder();
  static const _dptDepth = DptDepthDecoder();

  /// A [sentence]-t a `type`-ja alapján a megfelelő dekóderhez irányítja;
  /// `null` ha a `type` nem támogatott, vagy ha a dekóder skippel.
  DecodedSentence? decode(Sentence sentence) => switch (sentence.type) {
    'MWV' => _mwvWind.decode(sentence),
    'MWD' => _mwdWindDirection.decode(sentence),
    'RMC' => _rmc.decode(sentence),
    'VTG' => _vtgCogSog.decode(sentence),
    'GGA' => _ggaPosition.decode(sentence),
    'GLL' => _gllPosition.decode(sentence),
    'HDG' => _hdgHeading.decode(sentence),
    'VHW' => _vhwSpeed.decode(sentence),
    'DBT' => _dbtDepth.decode(sentence),
    'DPT' => _dptDepth.decode(sentence),
    _ => null,
  };
}
