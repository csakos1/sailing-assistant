import 'dart:io';

import 'package:args/args.dart';
import 'package:race_analyzer/race_analyzer.dart';

// ---------------------------------------------------------------------------
// race_analyzer — post-race elemzo a snapshot_logs-on (vekony CLI).
//
// A kov-boja-TWA predikcio minoseget meri a rogzitett (eles) outputbol
// (ADR 0025): predikalt-vs-tenyleges TWA, sav-talalat, megbizhatosag-elony.
// Az elemzo-logika a lib/-ben (a fixture-teszt is azt hivja); ez csak az
// arg-parse + az I/O-hej. A tool kizarolag OLVAS.
// ---------------------------------------------------------------------------

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag(
      'jsonl',
      negatable: false,
      help: 'A bemenet JSON-lines fixtura (nem SQLite DB).',
    )
    ..addFlag(
      'list-races',
      negatable: false,
      help: 'A snapshot_logs-ban levo race-ek listazasa (DB-input).',
    )
    ..addOption(
      'race',
      help: 'A race_id, amit elemezni kell (DB-input; tobb race eseten kell).',
    )
    ..addFlag(
      'csv',
      negatable: false,
      help: 'A delta-tabla CSV-kent stdoutra (a szoveges report helyett).',
    )
    ..addOption(
      'settle-skip',
      defaultsTo: '10',
      help: 'A korozes utan kihagyott masodpercek (beallas).',
    )
    ..addOption(
      'settle-window',
      defaultsTo: '20',
      help: 'A beallas utani atlagolasi ablak masodpercben.',
    )
    ..addOption(
      'lead-threshold',
      defaultsTo: 'high',
      help:
          'A lead-time-hoz megbizhatonak szamito szintek, vesszovel '
          '(pl. "high" vagy "medium,high").',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Sugo.');

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

  final path = results.rest.first;
  if (!File(path).existsSync()) {
    stderr.writeln('A bemeneti fajl nem talalhato: $path');
    exitCode = 66; // EX_NOINPUT
    return;
  }

  final params = _parseParams(results);
  if (params == null) {
    exitCode = 64;
    return;
  }

  final List<AnalyzerSnapshot> snapshots;
  if (results.flag('jsonl') || path.endsWith('.jsonl')) {
    snapshots = readSnapshotsFromJsonl(path);
  } else {
    // DB-input: race-listazas, vagy egy konkret race elemzese.
    final raceId = results.option('race');
    if (results.flag('list-races') || raceId == null) {
      _printRaceList(path);
      return;
    }
    snapshots = readSnapshotsFromDb(path, raceId);
  }

  if (snapshots.isEmpty) {
    stderr.writeln('Nincs snapshot a bemenetben.');
    exitCode = 65; // EX_DATAERR
    return;
  }

  final analysis = analyzeRoundings(snapshots, params: params);
  stdout.write(
    results.flag('csv') ? formatCsv(analysis) : formatReport(analysis),
  );
}

// A hangolasi flagek -> AnalysisParams; ervenytelen ertekre null + stderr.
AnalysisParams? _parseParams(ArgResults results) {
  final skip = int.tryParse(results.option('settle-skip') ?? '');
  final window = int.tryParse(results.option('settle-window') ?? '');
  if (skip == null || skip < 0) {
    stderr.writeln('Ervenytelen --settle-skip.');
    return null;
  }
  if (window == null || window <= 0) {
    stderr.writeln('Ervenytelen --settle-window.');
    return null;
  }
  final levels = (results.option('lead-threshold') ?? 'high')
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet();
  if (levels.isEmpty) {
    stderr.writeln('Ervenytelen --lead-threshold.');
    return null;
  }
  return AnalysisParams(
    settleSkip: Duration(seconds: skip),
    settleWindow: Duration(seconds: window),
    leadTrustLevels: levels,
  );
}

void _printRaceList(String dbPath) {
  final races = listRacesInDb(dbPath);
  if (races.isEmpty) {
    stdout.writeln('Nincs race a snapshot_logs-ban.');
    return;
  }
  stdout.writeln('${races.length} race a snapshot_logs-ban:\n');
  for (final race in races) {
    final marks = race.markNames.isEmpty
        ? '-'
        : (race.markNames.toList()..sort()).join(',');
    stdout.writeln(
      '  race_id=${race.raceId}  n=${race.snapshotCount}  '
      '~${race.span.inMinutes} perc  nev=${race.raceName ?? '?'}  '
      'bojak=$marks',
    );
  }
  stdout.writeln('\nElemzeshez: race_analyzer <db> --race <race_id>');
}

String _usage(ArgParser parser) =>
    'Hasznalat: race_analyzer <snapshot_logs.sqlite | fixtura.jsonl> '
    '[opciok]\n\n'
    'Post-race elemzo a kov-boja-TWA predikcio minosegere (ADR 0025):\n'
    'predikalt-vs-tenyleges TWA, sav-talalat, megbizhatosag-elony.\n\n'
    '${parser.usage}';
