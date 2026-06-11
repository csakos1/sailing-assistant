import 'dart:io';

import 'package:args/args.dart';
import 'package:domain/domain.dart';
import 'package:prediction_probe/prediction_probe.dart';

// ---------------------------------------------------------------------------
// prediction_probe — read-only replay-harness (vékony CLI).
//
// A vízi log `telemetry_records` soraiból (TSV: `ts<TAB>$…*XX`) a
// VALÓDI domain use case-eken futtatja az ADR 0020/0021 predikciós
// pipeline-t. A replay-motor a `lib/src/replay_engine.dart`-ban él (a
// fixture-teszt is azt hívja):
//   * ADR 0020: TWD a `DeriveTrueWindDirection`-ből (COG + csúcs-TWA,
//     SOG-kapu, hold-last-good).
//   * ADR 0021: köv-bója-TWA a `ComputeMarkPrediction`-ből
//     (köv-szár-irány, konfidencia-kapuzás, ±30° cap, 50 m freeze,
//     utolsó lábon null).
//   * Megkerülés: a domain `MarkRoundingDetector` (50 m + 5 m).
//
// FONTOS: ez kizárólag OLVAS és KIÍR — semmilyen alkalmazás-állapotot
// nem ír.
// ---------------------------------------------------------------------------

/// Bearing-számító a trace `leg=` oszlopához (csak display).
const _bearing = CalculateBearingToMark();

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

  final lines = file.readAsLinesSync();
  final report = PredictionReplay(
    marks: marks,
    window: Duration(minutes: windowMinutes),
    sampleInterval: Duration(seconds: sampleSeconds),
  ).run(lines);

  stdout
    ..writeln('# prediction_probe — read-only replay (ADR 0020/0021)')
    ..writeln('# pálya: ${marks.map((m) => m.name).join(' → ')}')
    ..writeln(
      '# ablak=$windowMinutes perc, minta=$sampleSeconds mp, '
      'sorok=${lines.length}, minták=${report.samples.length}, '
      'megkerülések=${report.roundings.length}',
    )
    ..writeln('# TWA előjel: + = jobb (starboard), - = bal (port)')
    ..writeln('#');

  _printReport(report, nearMeters: nearMeters);
}

/// A report kiírása időrendben: a megkerülés-sorok a trace-sorok közé
/// fűzve, az időbélyegük szerint.
void _printReport(ReplayReport report, {required double nearMeters}) {
  var nextRounding = 0;

  void flushRoundingsUpTo(DateTime upTo) {
    while (nextRounding < report.roundings.length &&
        !report.roundings[nextRounding].at.isAfter(upTo)) {
      final event = report.roundings[nextRounding];
      stdout.writeln(
        '# ${_hms(event.at)}  >> megkerült bója: ${event.rounded.name} '
        '(új aktív: ${event.newActive?.name ?? "—"})',
      );
      nextRounding++;
    }
  }

  for (final sample in report.samples) {
    flushRoundingsUpTo(sample.at);
    _printSample(sample, nearMeters);
  }
  if (report.roundings.isNotEmpty) {
    flushRoundingsUpTo(report.roundings.last.at);
  }
}

/// Egy trace-sor a mintavételből; a számokat a valódi `MarkPrediction`
/// adja.
void _printSample(ProbeSample sample, double nearMeters) {
  final prediction = sample.prediction;
  final active = sample.activeMark;
  if (prediction == null || active == null) {
    stdout.writeln('${_hms(sample.at)}  [VÉGE / nincs aktív bója]');
    return;
  }
  final next = sample.nextMark;
  final trend = sample.trend;
  final cogDeg = sample.cogDeg;
  final sogKnots = sample.sogKnots;
  final eta = prediction.eta;

  final rate = trend == null
      ? '   —   '
      : '${trend.shiftRateDegPerMinute >= 0 ? '+' : ''}'
            '${trend.shiftRateDegPerMinute.toStringAsFixed(1)}°/min';
  final conf = trend?.confidence.name ?? '—';
  // Az íven látszó, band-alapú bucket (ADR 0023) — nem a conf= r²-kapuja.
  final uiConf = prediction.shiftConfidence.name;
  final legBearing = next == null
      ? '  —'
      : _bearing(active.position, next.position).degrees.round().toString();
  final etaText = eta == null ? '  —' : '${eta.inSeconds}s';
  final meters = prediction.distanceToMark.meters;
  final near = meters <= nearMeters ? '  <-- KÖZEL ${active.name}' : '';

  stdout.writeln(
    '${_hms(sample.at)}  ${active.name}→${next?.name ?? "—"}  '
    'd=${meters.round().toString().padLeft(4)}m  '
    'COG=${cogDeg == null ? "  —" : cogDeg.round().toString().padLeft(3)} '
    'SOG=${sogKnots == null ? " — " : sogKnots.toStringAsFixed(1)}  '
    'TWD=${sample.twd.degrees.round().toString().padLeft(3)}'
    '(${sample.twdQuality.name})  '
    'rate=$rate conf=${conf.padRight(6)} uiconf=${uiConf.padRight(6)} '
    'eta=${etaText.padLeft(5)} leg=$legBearing  '
    'PRED=${_fmtTwa(prediction.predictedTwaAtMark)} '
    'band=${_fmtBand(prediction.forecastBandDegrees)}$near',
  );
}

/// A `--mark name,lat,lon` listából rendezett [Mark] pálya, vagy
/// `null` (+stderr), ha bármelyik bejegyzés rossz, vagy 2-nél kevesebb
/// bója van.
List<Mark>? _parseMarks(List<String> specs) {
  final marks = <Mark>[];
  for (final (index, spec) in specs.indexed) {
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
    marks.add(
      Mark(
        sequence: index + 1,
        name: p[0],
        position: Coordinate(latitude: lat, longitude: lon),
      ),
    );
  }
  if (marks.length < 2) {
    stderr.writeln('Legalább 2 --mark kell (activeMark + nextMark).');
    return null;
  }
  return marks;
}

/// Az `Angle` TWA emberi formája: `jobb`/`bal` + fok, `null` → `—`.
String _fmtTwa(Angle? twa) {
  if (twa == null) return '   —    ';
  final side = twa.degrees >= 0 ? 'jobb' : 'bal ';
  return '$side ${twa.degrees.abs().round().toString().padLeft(3)}°';
}

/// A predikció hibasávja (band) emberi formája fokban; `null` → `—`.
String _fmtBand(double? band) =>
    band == null ? '—' : '±${band.toStringAsFixed(1)}°';

/// `HH:MM:SS` az időbélyegből (UTC).
String _hms(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}:'
    '${t.second.toString().padLeft(2, '0')}';

/// Használati súgó.
String _usage(ArgParser parser) =>
    'Usage: dart run tools/prediction_probe/bin/prediction_probe.dart '
    '<telemetry.tsv> --mark name,lat,lon [--mark ...]\n\n${parser.usage}';
