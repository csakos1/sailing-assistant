import 'package:domain/domain.dart';
import 'package:prediction_probe/src/probe_report.dart';

/// Csomó → m/s szorzó (1 kn = 0.514444 m/s).
const double _knotToMps = 0.514444;

/// Read-only replay-motor: a telemetria-TSV sorokból (`ts<TAB>$…*XX`)
/// gördülő hajó- és szél-állapotot épít, és a VALÓDI domain use
/// case-eken futtatja a predikciós pipeline-t (ADR 0020/0021):
///
/// - TWD: [DeriveTrueWindDirection] (COG + csúcs-TWA, SOG-kapu +
///   hold-last-good), a `race_engine` `_lastGoodTwd`-görgetését
///   tükrözve;
/// - trend: [CalculateWindShiftTrend] a downsample-elt historyn;
/// - predikció: [ComputeMarkPrediction] (köv-szár-irány, konfidencia-
///   kapuzás, ±30° cap, 50 m freeze, utolsó lábon null);
/// - megkerülés: [MarkRoundingDetector] (50 m küszöb + 5 m
///   hiszterézis).
///
/// A 0183-mezőkinyerés minimál inline marad: a valódi parser a `data`
/// Flutter-package-ben él, ami pure Dart toolból nem importálható —
/// dokumentáltan elfogadott kivétel (a probe csak mezőket emel ki,
/// üzleti logikát nem duplikál).
///
/// A [run] újrahívható: induláskor minden belső állapotot nulláz.
class PredictionReplay {
  /// Új replay-motor a [marks] pályával (a megkerülés sorrendjében).
  PredictionReplay({
    required List<Mark> marks,
    this.window = const Duration(minutes: 10),
    this.sampleInterval = const Duration(seconds: 60),
  }) : _marks = List.unmodifiable(marks);

  /// A wind-shift regresszió csúszóablaka.
  final Duration window;

  /// A TWD-history downsample- és trace-mintavételi ütem.
  final Duration sampleInterval;

  final List<Mark> _marks;
  final MarkRoundingDetector _detector = MarkRoundingDetector();
  final List<WindObservation> _history = [];

  static const _derive = DeriveTrueWindDirection();
  static const _trendCalc = CalculateWindShiftTrend();
  static const _compute = ComputeMarkPrediction();

  int _activeIndex = 0;
  Bearing? _lastGoodTwd;
  DateTime? _lastSample;

  /// Lefuttatja a replayt a [lines] TSV-sorain. Kizárólag olvas —
  /// alkalmazás-állapotot nem ír.
  ReplayReport run(List<String> lines) {
    _activeIndex = 0;
    _lastGoodTwd = null;
    _lastSample = null;
    _history.clear();
    _detector.reset();

    final samples = <ProbeSample>[];
    final roundings = <RoundingEvent>[];
    final state = _RollingState();

    for (final line in lines) {
      final parsed = _parseLine(line);
      if (parsed == null) continue;
      _applySentence(state, parsed.parts);
      _maybeRound(parsed.at, state.position, roundings);

      final boat = _boatState(parsed.at, state);
      final estimate = _deriveTwd(boat, state.bowTwa, parsed.at);
      final sample = _sampleIfDue(parsed.at, boat, estimate);
      if (sample != null) {
        samples.add(sample);
      }
    }
    return ReplayReport(samples: samples, roundings: roundings);
  }

  /// Megkerülés-tick a domain detektorral; találatkor a következő
  /// bójára lép és reseteli a detektort (level-trigger szerződés).
  void _maybeRound(
    DateTime now,
    Coordinate? position,
    List<RoundingEvent> out,
  ) {
    if (position == null || _activeIndex >= _marks.length) {
      return;
    }
    if (!_detector.tick(position, _marks[_activeIndex])) {
      return;
    }
    final rounded = _marks[_activeIndex];
    _activeIndex++;
    _detector.reset();
    out.add(
      RoundingEvent(
        at: now,
        rounded: rounded,
        newActive: _activeIndex < _marks.length ? _marks[_activeIndex] : null,
      ),
    );
  }

  /// A gördülő nyers mezőkből épített [BoatState] snapshot.
  BoatState _boatState(DateTime now, _RollingState state) {
    return BoatState(
      lastUpdate: now,
      position: state.position,
      courseOverGround: state.cog,
      speedOverGround: state.sog,
    );
  }

  /// TWD-deriválás a valódi use case-szel; a `_lastGoodTwd` a
  /// `race_engine` mintájára csak `live` minőségnél gördül.
  TwdEstimate _deriveTwd(BoatState boat, Angle? bowTwa, DateTime now) {
    final wind = WindData(
      // A deriválás az apparent mezőket nem olvassa; a WindData
      // ctor-ban viszont kötelezők -> semleges placeholder.
      apparentAngle: const Angle(degrees: 0),
      apparentSpeed: const Speed(metersPerSecond: 0),
      timestamp: now,
      trueAngleWater: bowTwa,
    );
    final estimate = _derive(
      boatState: boat,
      wind: wind,
      lastGoodTwd: _lastGoodTwd,
    );
    if (estimate.quality == TwdQuality.live) {
      _lastGoodTwd = estimate.twd;
    }
    return estimate;
  }

  /// A mintavételi ütemen: TWD-history bővítés (30 perces pufferrel),
  /// trend + a valódi composite predikció. `null`, ha nincs TWD vagy
  /// még nem járt le az ütem.
  ProbeSample? _sampleIfDue(
    DateTime now,
    BoatState boat,
    TwdEstimate estimate,
  ) {
    final twd = estimate.twd;
    if (twd == null) {
      return null;
    }
    final last = _lastSample;
    if (last != null && now.difference(last) < sampleInterval) {
      return null;
    }
    _lastSample = now;

    _history.add(
      WindObservation(
        twd: twd,
        timestamp: now,
        twdQuality: estimate.quality,
      ),
    );
    // 30 perces puffer (a windHistoryProvider ablakát követve).
    final cutoff = now.subtract(const Duration(minutes: 30));
    _history.removeWhere((o) => o.timestamp.isBefore(cutoff));

    final active = _activeIndex < _marks.length ? _marks[_activeIndex] : null;
    final next = _activeIndex + 1 < _marks.length
        ? _marks[_activeIndex + 1]
        : null;
    final trend = _trendCalc(history: _history, window: window, now: now);
    final sog = boat.speedOverGround;

    return ProbeSample(
      at: now,
      twd: twd,
      twdQuality: estimate.quality,
      activeMark: active,
      nextMark: next,
      cogDeg: boat.courseOverGround?.degrees,
      sogKnots: sog == null ? null : sog.metersPerSecond / _knotToMps,
      trend: trend,
      prediction: _compute(
        activeMark: active,
        nextMark: next,
        boatState: boat,
        trend: trend,
        now: now,
      ),
    );
  }
}

/// A soronként gördülő nyers NMEA-mezők. Utolsó-ismert-érték
/// szemantika: a sikertelen parse (`null`) nem töröl meglévő mezőt.
class _RollingState {
  Coordinate? position;
  Angle? bowTwa;
  Bearing? cog;
  Speed? sog;

  void setCogDeg(double? degrees) {
    if (degrees == null) return;
    cog = Bearing.true_(degrees % 360);
  }

  void setSogKnots(double? knots) {
    if (knots == null) return;
    sog = Speed(metersPerSecond: knots * _knotToMps);
  }
}

/// Egy TSV-sor: unix-mp időbélyeg + a mondat mező-tömbje, vagy `null`,
/// ha a sor nem értelmezhető.
({DateTime at, List<String> parts})? _parseLine(String line) {
  final tab = line.indexOf('\t');
  if (tab < 0) return null;
  final ts = int.tryParse(line.substring(0, tab));
  if (ts == null) return null;
  final parts = _splitFields(line.substring(tab + 1));
  if (parts == null) return null;
  return (
    at: DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true),
    parts: parts,
  );
}

/// A mondat-típus szerinti gördülő-állapot frissítés. Minimál
/// mezőkinyerés — lásd a [PredictionReplay] class-doc
/// kivétel-indoklását.
void _applySentence(_RollingState state, List<String> parts) {
  final fields = parts.sublist(1);
  switch (_sentenceType(parts)) {
    case 'RMC':
      if (fields.length >= 8 && fields[1] == 'A') {
        final lat = _parseLatLon(fields[2], fields[3]);
        final lon = _parseLatLon(fields[4], fields[5]);
        if (lat != null && lon != null) {
          state.position = Coordinate(latitude: lat, longitude: lon);
        }
        state
          ..setSogKnots(double.tryParse(fields[6]))
          ..setCogDeg(double.tryParse(fields[7]));
      }
    case 'VTG':
      if (fields.isNotEmpty) {
        state.setCogDeg(double.tryParse(fields[0]));
      }
      if (fields.length >= 5) {
        state.setSogKnots(double.tryParse(fields[4]));
      }
    case 'GGA':
      if (fields.length >= 5) {
        final lat = _parseLatLon(fields[1], fields[2]);
        final lon = _parseLatLon(fields[3], fields[4]);
        if (lat != null && lon != null) {
          state.position = Coordinate(latitude: lat, longitude: lon);
        }
      }
    case 'GLL':
      // f[5] státusz: 'V' érvénytelen fix -> kihagyjuk.
      if (fields.length >= 4 && (fields.length < 6 || fields[5] != 'V')) {
        final lat = _parseLatLon(fields[0], fields[1]);
        final lon = _parseLatLon(fields[2], fields[3]);
        if (lat != null && lon != null) {
          state.position = Coordinate(latitude: lat, longitude: lon);
        }
      }
    case 'MWV':
      // Csak a 'T' (true, csúcs-relatív) és 'A' (valid) MWV érdekes.
      // Az előjel-konvenció nem számít: a deriválás a mod-360 wrap
      // miatt sign-agnosztikus (lásd a DeriveTrueWindDirection docot).
      if (fields.length >= 5 && fields[1] == 'T' && fields[4] == 'A') {
        final raw = double.tryParse(fields[0]);
        if (raw != null) {
          state.bowTwa = Angle(degrees: raw % 360);
        }
      }
  }
}

/// Egy NMEA mondat mező-tömbje: a `$`/`!`-tól, a `*CS` levágva.
/// `null`, ha nincs kezdőjel vagy 2-nél kevesebb mező.
List<String>? _splitFields(String sentence) {
  final start = sentence.indexOf(RegExp(r'[$!]'));
  if (start < 0) return null;
  var body = sentence.substring(start + 1);
  final star = body.indexOf('*');
  if (star >= 0) body = body.substring(0, star);
  final parts = body.split(',');
  return parts.length < 2 ? null : parts;
}

/// A mondat 3 betűs típusa (pl. `RMC`), a 2 betűs talker után.
String _sentenceType(List<String> parts) {
  final address = parts.first;
  return address.length >= 3 ? address.substring(address.length - 3) : address;
}

/// NMEA `DDMM.mmmm` / `DDDMM.mmmm` + hemiszféra → decimális fok, vagy
/// `null`.
double? _parseLatLon(String value, String hemisphere) {
  if (value.isEmpty) return null;
  final raw = double.tryParse(value);
  if (raw == null) return null;
  final wholeDegrees = (raw ~/ 100).toDouble();
  final minutes = raw - wholeDegrees * 100;
  final result = wholeDegrees + minutes / 60;
  return hemisphere == 'S' || hemisphere == 'W' ? -result : result;
}
