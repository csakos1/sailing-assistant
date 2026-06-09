import 'dart:io';

import 'package:args/args.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

// ---------------------------------------------------------------------------
// prediction_probe — read-only replay-harness.
//
// A 2026-06-06-i vízi log `telemetry_records` soraiból (TSV: `ts<TAB>$…*XX`)
// kiszámolja a JÖVŐBELI predikciós logikát — a kódmódosítás ELŐTT, hogy
// papíron igazoljuk az ADR 0020/0021 fixet:
//   * ADR 0020: TWD = normalize360(COG_true + csúcs-relatív TWA), SOG-kapuval
//     és hold-last-good logikával (a `MWD`/iránytű-alapú TWD-t kerüljük).
//   * ADR 0021: a köv-bója-TWA a KÖVETKEZŐ szárra (legBearing =
//     bearing(activeMark → nextMark)), konfidencia-kapuzott + ±30° cap-elt
//     extrapolációval, 50 m freeze-szel, utolsó lábon null.
//
// A regressziót (`CalculateWindShiftTrend`) és a geometriát
// (`CalculateBearingToMark/DistanceToMark/EtaToMark`) a VALÓDI domain
// use-case-ekből hívjuk — csak a még nem implementált TWD-forrást és a
// kapuzott köv-szár-geometriát modellezi ez a harness. A 0183-mezőkinyerés
// minimál inline (a valódi parser a `data` Flutter-package-ben él).
//
// FONTOS: ez kizárólag OLVAS és KIÍR — semmilyen alkalmazás-állapotot nem ír.
// ---------------------------------------------------------------------------

/// Csomó → m/s szorzó (1 kn = 0.514444 m/s).
const double _knotToMps = 0.514444;

/// ADR 0020 D2: e SOG (csomó) alatt a COG zajos → hold-last-good TWD.
const double _cogValidMinSpeedKnots = 1.5;

/// Megkerülés-detektálás sugara (az app `MarkRoundingDetector` 50 m-ével).
const double _markRoundingRadiusMeters = 50;

/// Megkerülés-hiszterézis: ennyivel a sugár fölé érve számít kilépésnek.
const double _markRoundingHysteresisMeters = 5;

/// ADR 0021 D4: e sugáron belül a predikciót befagyasztjuk (null).
const double _freezeRadiusMeters = 50;

/// ADR 0021 D3: a kapuzott extrapoláció abszolút plafonja (fok).
const double _maxExtrapolationDeg = 30;

/// Egy pálya-bója: név + koordináta, a `--mark name,lat,lon` sorrendjében.
typedef _CourseMark = ({String name, Coordinate coord});

/// A `prediction_probe` belépési pontja. A pozícionális argumentum a
/// telemetria-TSV útja; a `--mark` opciók adják a pályát sorrendben.
void main(List<String> arguments) {
  final parser = ArgParser()
    ..addMultiOption(
      'mark',
      abbr: 'm',
      splitCommas: false,
      help:
          'Pálya-bója `name,lat,lon` formátumban, a megkerülés sorrendjében '
          '(ismételhető).',
    )
    ..addOption(
      'window-minutes',
      defaultsTo: '10',
      help: 'A wind-shift regresszió csúszóablaka percben.',
    )
    ..addOption(
      'sample-interval-seconds',
      defaultsTo: '60',
      help: 'A TWD-history downsample-ütem (és a trace-kiírás üteme) mp-ben.',
    )
    ..addOption(
      'near-marker-meters',
      defaultsTo: '200',
      help: 'Ezen távolság alatt a sor [KÖZEL] jelölést kap az aktív bójához.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Súgó.');

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(_usage(parser));
    exitCode = 64; // EX_USAGE
    return;
  }

  if (results.flag('help') || results.rest.isEmpty) {
    stdout.writeln(_usage(parser));
    return;
  }

  final windowMinutes = int.tryParse(results.option('window-minutes') ?? '');
  final sampleSeconds = int.tryParse(
    results.option('sample-interval-seconds') ?? '',
  );
  final nearMeters = double.tryParse(
    results.option('near-marker-meters') ?? '',
  );
  if (windowMinutes == null || windowMinutes <= 0) {
    stderr.writeln('Érvénytelen --window-minutes.');
    exitCode = 64;
    return;
  }
  if (sampleSeconds == null || sampleSeconds <= 0) {
    stderr.writeln('Érvénytelen --sample-interval-seconds.');
    exitCode = 64;
    return;
  }
  if (nearMeters == null || nearMeters <= 0) {
    stderr.writeln('Érvénytelen --near-marker-meters.');
    exitCode = 64;
    return;
  }

  final marks = _parseMarks(results.multiOption('mark'));
  if (marks == null) {
    exitCode = 64;
    return;
  }

  final logPath = results.rest.first;
  final file = File(logPath);
  if (!file.existsSync()) {
    stderr.writeln('A logfájl nem található: $logPath');
    exitCode = 66; // EX_NOINPUT
    return;
  }

  _run(
    lines: file.readAsLinesSync(),
    marks: marks,
    window: Duration(minutes: windowMinutes),
    sampleInterval: Duration(seconds: sampleSeconds),
    nearMeters: nearMeters,
  );
}

/// Lefuttatja a teljes elemzést: soronként frissíti a gördülő állapotot,
/// detektálja a megkerülést, és a downsample-ütemen trace-sort ír.
void _run({
  required List<String> lines,
  required List<_CourseMark> marks,
  required Duration window,
  required Duration sampleInterval,
  required double nearMeters,
}) {
  const bearing = CalculateBearingToMark();
  const distance = CalculateDistanceToMark();
  const etaCalc = CalculateEtaToMark();
  const trendCalc = CalculateWindShiftTrend();

  Coordinate? position;
  double? cogDeg;
  double? sogKnots;
  double? bowTwaSigned;
  Bearing? lastGoodTwd;
  final history = <WindObservation>[];
  var activeIndex = 0;
  var wasInsideActive = false;
  DateTime? lastSample;

  stdout
    ..writeln('# prediction_probe — read-only replay (ADR 0020/0021)')
    ..writeln('# pálya: ${marks.map((m) => m.name).join(' → ')}')
    ..writeln(
      '# ablak=${window.inMinutes} perc, '
      'minta=${sampleInterval.inSeconds} mp, sorok=${lines.length}',
    )
    ..writeln('# TWA előjel: + = jobb (starboard), - = bal (port)')
    ..writeln('#');

  for (final line in lines) {
    final tab = line.indexOf('\t');
    if (tab < 0) continue;
    final ts = int.tryParse(line.substring(0, tab));
    if (ts == null) continue;
    final now = DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true);

    final parts = _splitFields(line.substring(tab + 1));
    if (parts == null) continue;
    final fields = parts.sublist(1);

    switch (_sentenceType(parts)) {
      case 'RMC':
        if (fields.length >= 8 && fields[1] == 'A') {
          final lat = _parseLatLon(fields[2], fields[3]);
          final lon = _parseLatLon(fields[4], fields[5]);
          if (lat != null && lon != null) {
            position = Coordinate(latitude: lat, longitude: lon);
          }
          sogKnots = double.tryParse(fields[6]) ?? sogKnots;
          cogDeg = double.tryParse(fields[7]) ?? cogDeg;
        }
      case 'VTG':
        if (fields.isNotEmpty) cogDeg = double.tryParse(fields[0]) ?? cogDeg;
        if (fields.length >= 5) {
          sogKnots = double.tryParse(fields[4]) ?? sogKnots;
        }
      case 'GGA':
        if (fields.length >= 5) {
          final lat = _parseLatLon(fields[1], fields[2]);
          final lon = _parseLatLon(fields[3], fields[4]);
          if (lat != null && lon != null) {
            position = Coordinate(latitude: lat, longitude: lon);
          }
        }
      case 'GLL':
        // f[5] státusz: 'V' érvénytelen fix → kihagyjuk.
        if (fields.length >= 4 && (fields.length < 6 || fields[5] != 'V')) {
          final lat = _parseLatLon(fields[0], fields[1]);
          final lon = _parseLatLon(fields[2], fields[3]);
          if (lat != null && lon != null) {
            position = Coordinate(latitude: lat, longitude: lon);
          }
        }
      case 'MWV':
        // Csak a 'T' (true, csúcs-relatív) és 'A' (valid) MWV érdekel.
        if (fields.length >= 5 && fields[1] == 'T' && fields[4] == 'A') {
          final raw = double.tryParse(fields[0]);
          if (raw != null) {
            final norm = raw % 360;
            // 0..360 csúcs-szög → előjeles [-180,180): >180 = bal (port).
            bowTwaSigned = norm > 180 ? norm - 360 : norm;
          }
        }
    }

    // --- Megkerülés-detektálás minden pozíció-frissítésnél (50 m + 5 m) ---
    final pos = position;
    if (pos != null && activeIndex < marks.length) {
      final d = distance(pos, marks[activeIndex].coord).meters;
      if (d <= _markRoundingRadiusMeters) {
        wasInsideActive = true;
      } else if (wasInsideActive &&
          d > _markRoundingRadiusMeters + _markRoundingHysteresisMeters) {
        activeIndex++;
        wasInsideActive = false;
        stdout.writeln(
          '# ${_hms(now)}  >> megkerült bója: '
          '${marks[activeIndex - 1].name} '
          '(új aktív: ${activeIndex < marks.length ? marks[activeIndex].name : "—"})',
        );
      }
    }

    // --- TWD = COG + csúcs-TWA (ADR 0020), SOG-kapuval + hold-last-good ---
    final cog = cogDeg;
    final bowTwa = bowTwaSigned;
    final sog = sogKnots;
    Bearing? twd;
    var quality = 'unavailable';
    if (cog != null &&
        bowTwa != null &&
        sog != null &&
        sog >= _cogValidMinSpeedKnots) {
      twd = Bearing.true_((cog + bowTwa) % 360);
      lastGoodTwd = twd;
      quality = 'live';
    } else if (lastGoodTwd != null) {
      twd = lastGoodTwd;
      quality = 'held';
    }

    // --- Downsample + trace a megadott ütemen ---
    if (twd != null &&
        (lastSample == null || now.difference(lastSample) >= sampleInterval)) {
      history.add(WindObservation(twd: twd, timestamp: now));
      lastSample = now;
      // 30 perces puffer (a windHistoryProvider ablakát követve).
      final cutoff = now.subtract(const Duration(minutes: 30));
      history.removeWhere((o) => o.timestamp.isBefore(cutoff));

      _emitTrace(
        now: now,
        position: pos,
        marks: marks,
        activeIndex: activeIndex,
        cogDeg: cog,
        sogKnots: sog,
        twd: twd,
        quality: quality,
        trend: trendCalc(history: history, window: window, now: now),
        nearMeters: nearMeters,
        bearing: bearing,
        distance: distance,
        etaCalc: etaCalc,
      );
    }
  }
}

/// Egyetlen trace-sor: aktuális állapot + a kapuzott köv-bója-TWA (ADR 0021).
void _emitTrace({
  required DateTime now,
  required Coordinate? position,
  required List<_CourseMark> marks,
  required int activeIndex,
  required double? cogDeg,
  required double? sogKnots,
  required Bearing twd,
  required String quality,
  required WindShiftTrend? trend,
  required double nearMeters,
  required CalculateBearingToMark bearing,
  required CalculateDistanceToMark distance,
  required CalculateEtaToMark etaCalc,
}) {
  if (position == null || activeIndex >= marks.length) {
    stdout.writeln('${_hms(now)}  [VÉGE / nincs aktív bója]');
    return;
  }
  final active = marks[activeIndex];
  final next = activeIndex + 1 < marks.length ? marks[activeIndex + 1] : null;
  final dist = distance(position, active.coord);
  final eta = etaCalc(
    distance: dist,
    speedOverGround: sogKnots == null ? null : _knotsToSpeed(sogKnots),
  );

  final predicted = _predictNextLegTwa(
    distanceToActive: dist,
    activeMark: active.coord,
    nextMark: next?.coord,
    eta: eta,
    trend: trend,
    bearing: bearing,
  );

  final rate = trend == null
      ? '   —   '
      : '${trend.shiftRateDegPerMinute >= 0 ? '+' : ''}'
            '${trend.shiftRateDegPerMinute.toStringAsFixed(1)}°/min';
  final conf = trend?.confidence.name ?? '—';
  final legBearing = next == null
      ? '  —'
      : bearing(active.coord, next.coord).degrees.round();
  final etaText = eta == null ? '  —' : '${eta.inSeconds}s';
  final near = dist.meters <= nearMeters ? '  <-- KÖZEL ${active.name}' : '';

  stdout.writeln(
    '${_hms(now)}  ${active.name}→${next?.name ?? "—"}  '
    'd=${dist.meters.round().toString().padLeft(4)}m  '
    'COG=${cogDeg == null ? "  —" : cogDeg.round().toString().padLeft(3)} '
    'SOG=${sogKnots == null ? " — " : sogKnots.toStringAsFixed(1)}  '
    'TWD=${twd.degrees.round().toString().padLeft(3)}($quality)  '
    'rate=$rate conf=${conf.padRight(6)} '
    'eta=${etaText.padLeft(5)} leg=$legBearing  '
    'PRED=${_fmtTwa(predicted)}$near',
  );
}

/// A köv-bója-TWA az ADR 0021 szerint: a következő szárra extrapolált,
/// konfidencia-kapuzott, ±30° cap-elt érték; `null` utolsó lábon, freeze-
/// sugáron belül, vagy ha nincs trend/eta.
Angle? _predictNextLegTwa({
  required Distance distanceToActive,
  required Coordinate activeMark,
  required Coordinate? nextMark,
  required Duration? eta,
  required WindShiftTrend? trend,
  required CalculateBearingToMark bearing,
}) {
  if (nextMark == null) return null; // utolsó láb (ADR 0021 D2)
  if (distanceToActive.meters <= _freezeRadiusMeters) return null; // D4
  if (trend == null || eta == null) return null;

  // ADR 0021 D3: low-konfidencia (r² ≤ 0.4) → nincs extrapoláció.
  final effectiveRate = trend.confidence == WindShiftConfidence.low
      ? 0.0
      : trend.shiftRateDegPerMinute;
  // effectiveEta = min(eta, ablak) — a hosszú-ETA sodródás ellen.
  final etaSeconds = eta.inSeconds;
  final windowSeconds = trend.windowDuration.inSeconds;
  final effectiveSeconds = etaSeconds < windowSeconds
      ? etaSeconds
      : windowSeconds;
  // ±30° cap.
  final shiftDeg = (effectiveRate * effectiveSeconds / 60).clamp(
    -_maxExtrapolationDeg,
    _maxExtrapolationDeg,
  );

  final predictedTwd = trend.currentTwd + Angle(degrees: shiftDeg);
  // ADR 0021 D1: a fix következő-szár irányhoz mért signed TWA.
  return predictedTwd - bearing(activeMark, nextMark);
}

/// `Speed` a SOG-csomóból, vagy `null` ha az érték érvénytelen.
Speed? _knotsToSpeed(double knots) {
  return switch (Speed.tryFromMetersPerSecond(
    metersPerSecond: knots * _knotToMps,
  )) {
    Ok(value: final s) => s,
    Err() => null,
  };
}

/// A `--mark name,lat,lon` listából rendezett pálya, vagy `null` (+stderr)
/// ha bármelyik bejegyzés rossz, vagy 2-nél kevesebb bója van.
List<_CourseMark>? _parseMarks(List<String> specs) {
  final marks = <_CourseMark>[];
  for (final spec in specs) {
    final p = spec.split(',');
    if (p.length != 3) {
      stderr.writeln('Rossz --mark: "$spec" (várt: name,lat,lon).');
      return null;
    }
    final lat = double.tryParse(p[1]);
    final lon = double.tryParse(p[2]);
    if (lat == null || lon == null) {
      stderr.writeln('Rossz --mark koordináta: "$spec".');
      return null;
    }
    marks.add((name: p[0], coord: Coordinate(latitude: lat, longitude: lon)));
  }
  if (marks.length < 2) {
    stderr.writeln('Legalább 2 --mark kell (activeMark + nextMark).');
    return null;
  }
  return marks;
}

/// Egy NMEA mondat mező-tömbje: a `$`/`!`-tól, a `*CS` levágva. `null`, ha
/// nincs kezdőjel vagy 2-nél kevesebb mező.
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

/// NMEA `DDMM.mmmm` / `DDDMM.mmmm` + hemiszféra → decimális fok, vagy `null`.
double? _parseLatLon(String value, String hemisphere) {
  if (value.isEmpty) return null;
  final raw = double.tryParse(value);
  if (raw == null) return null;
  final wholeDegrees = (raw ~/ 100).toDouble();
  final minutes = raw - wholeDegrees * 100;
  final result = wholeDegrees + minutes / 60;
  return hemisphere == 'S' || hemisphere == 'W' ? -result : result;
}

/// Az [Angle] TWA emberi formája: `jobb`/`bal` + fok, `null` → `—`.
String _fmtTwa(Angle? twa) {
  if (twa == null) return '   —    ';
  final side = twa.degrees >= 0 ? 'jobb' : 'bal ';
  return '$side ${twa.degrees.abs().round().toString().padLeft(3)}°';
}

/// `HH:MM:SS` az időbélyegből (UTC).
String _hms(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}:'
    '${t.second.toString().padLeft(2, '0')}';

/// Használati súgó.
String _usage(ArgParser parser) =>
    'Usage: dart run tools/prediction_probe/bin/prediction_probe.dart '
    '<telemetry.tsv> --mark name,lat,lon [--mark ...]\n\n${parser.usage}';
