import 'dart:io';

import 'package:args/args.dart';
import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/legacy/decode_legacy_sheet.dart';
import 'package:web_server/src/legacy/describe_legacy_import.dart';
import 'package:web_server/src/legacy/legacy_columns.dart';
import 'package:web_server/src/legacy/legacy_import_applier.dart';
import 'package:web_server/src/legacy/legacy_sheet.dart';
import 'package:web_server/src/legacy/normalize_legacy_row.dart';
import 'package:web_server/src/legacy/plan_legacy_import.dart';
import 'package:web_server/src/legacy/telemetry_candidate.dart';
import 'package:web_server/src/stats/race_stats_calculator.dart';
import 'package:web_server/src/stats/race_stats_refresher.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';
import 'package:web_server/src/web_db/web_database.dart';

// Az Excel-napló egyszeri importja (ADR 0048 D7 + Addendum 6). Alapból
// próbafuttatás: kiírja a tervet, és nem ír semmit. Az --apply ír, a
// --overwrite a meglévő kézi versenyt és eredményt is felülírja. A
// szerver fusson le előtte, ahogy az import_race_db-nél (M7).
//
//   python3 tools/legacy_race_log/xlsx_to_json.py Lola.xlsx > legacy.json
//   dart run web_server:import_legacy_races \
//     --archive /var/lib/foretack/archive.sqlite \
//     --web-db /var/lib/foretack/web.sqlite \
//     --json legacy.json [--match <race-id>=<sor> …] [--apply] [--overwrite]
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('archive', help: 'Az archívum SQLite-fájlja (kötelező).')
    ..addOption('web-db', help: 'A webes adatok SQLite-fájlja (kötelező).')
    ..addOption('json', help: 'Az xlsx_to_json.py kimenete (kötelező).')
    ..addMultiOption(
      'match',
      help: 'Kézi párosítás: <race-id>=<Excel-sor>, ismételhető.',
      splitCommas: false,
    )
    ..addFlag('apply', negatable: false, help: 'A terv végrehajtása.')
    ..addFlag(
      'overwrite',
      negatable: false,
      help: 'A meglévő kézi versenyt és eredményt is felülírja.',
    );

  final _Options options;
  try {
    options = _Options.parse(parser.parse(arguments));
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final String source;
  try {
    source = await File(options.jsonPath).readAsString();
  } on FileSystemException catch (error) {
    stderr.writeln(
      'A JSON nem olvasható: ${options.jsonPath}, ${error.message}',
    );
    exitCode = 66;
    return;
  }
  final LegacySheet sheet;
  switch (decodeLegacySheet(source)) {
    case Ok(:final value):
      sheet = value;
    case Err(:final error):
      stderr.writeln('A JSON nem olvasható: ${error.detail}');
      exitCode = 1;
      return;
  }

  final archive = AppDatabase(NativeDatabase(File(options.archivePath)));
  final webDatabase = WebDatabase(NativeDatabase(File(options.webDbPath)));
  try {
    await _run(options, sheet, archive, webDatabase);
  } finally {
    await archive.close();
    await webDatabase.close();
  }
}

Future<void> _run(
  _Options options,
  LegacySheet sheet,
  AppDatabase archive,
  WebDatabase webDatabase,
) async {
  final races = RaceRepositoryImpl(archive);
  final manualRaces = ManualRaceRepository(webDatabase);
  final results = RaceResultRepository(webDatabase);
  final existingManualRaces = await manualRaces.getAll();
  final plan = planLegacyImport(
    rows: sheet.rows.map(normalizeLegacyRow).toList(),
    telemetryRaces: await _telemetryCandidates(races),
    manualRaces: existingManualRaces,
    explicitMatches: options.matches,
  );
  final columns = checkLegacyColumns(sheet.columns);
  final lines = [
    ...describeLegacyColumns(
      unknown: columns.unknown,
      missing: columns.missing,
    ),
    ...describeLegacyPlan(
      plan,
      existingResultIds: (await results.getAll()).keys.toSet(),
      existingManualIds: {for (final race in existingManualRaces) race.id},
    ),
  ];
  for (final line in lines) {
    stdout.writeln(line);
  }
  if (!options.shouldApply) {
    stdout.writeln('Próbafuttatás: semmi nem íródott. Írás: --apply.');
    return;
  }
  if (columns.unknown.isNotEmpty || columns.missing.isNotEmpty) {
    stderr.writeln('A fejlécek eltérése miatt az import nem fut (M8).');
    exitCode = 1;
    return;
  }
  if (plan.matchProblems.isNotEmpty) {
    stderr.writeln('A --match hibái miatt az import nem fut.');
    exitCode = 1;
    return;
  }
  final refresher = RaceStatsRefresher(
    races: races,
    results: results,
    stats: RaceStatsRepository(webDatabase),
    calculate: RaceStatsCalculator(
      readTrackSamples: TrackSampleReaderImpl(archive).readWindow,
      readWindSamples: WindSampleReaderImpl(archive).call,
    ),
    log: stderr.writeln,
  );
  final applier = LegacyImportApplier(
    manualRaces: manualRaces,
    results: results,
    runInTransaction: webDatabase.transaction,
    refreshStats: refresher.refreshIfStale,
  );
  final report = await applier(plan, shouldOverwrite: options.shouldOverwrite);
  stdout.writeln('--- Végrehajtva ---');
  describeLegacyApply(report).forEach(stdout.writeln);
}

Future<List<TelemetryCandidate>> _telemetryCandidates(
  RaceRepository races,
) async => [
  for (final race in await races.watchRaces().first)
    if (race.status == RaceStatus.finished)
      if (race.startedAt case final startedAt?)
        TelemetryCandidate(id: race.id, name: race.name, startedAt: startedAt),
];

/// A kapcsolók ellenőrzött értékei.
final class _Options {
  _Options({
    required this.archivePath,
    required this.webDbPath,
    required this.jsonPath,
    required this.matches,
    required this.shouldApply,
    required this.shouldOverwrite,
  });

  factory _Options.parse(ArgResults results) => _Options(
    archivePath: _requiredOption(results, 'archive'),
    webDbPath: _requiredOption(results, 'web-db'),
    jsonPath: _requiredOption(results, 'json'),
    matches: _matchesOf(results.multiOption('match')),
    shouldApply: results.flag('apply'),
    shouldOverwrite: results.flag('overwrite'),
  );

  final String archivePath;
  final String webDbPath;
  final String jsonPath;
  final Map<String, int> matches;
  final bool shouldApply;
  final bool shouldOverwrite;
}

// Az import_race_db mintája (ADR 0048 Addendum 3 I8).
String _requiredOption(ArgResults options, String name) =>
    options.option(name) ??
    (throw FormatException('--$name: kötelező kapcsoló'));

final RegExp _matchPattern = RegExp(r'^([^=\s]+)=(\d+)$');

Map<String, int> _matchesOf(List<String> values) {
  final matches = <String, int>{};
  for (final value in values) {
    final match = _matchPattern.firstMatch(value.trim());
    if (match == null) {
      throw FormatException('--match $value: <race-id>=<sor> alak kell');
    }
    // A minta két kötelező csoportja nem üres, a második csupa számjegy.
    final raceId = match.group(1)!;
    if (matches.containsKey(raceId)) {
      throw FormatException('--match $raceId: többször megadva');
    }
    matches[raceId] = int.parse(match.group(2)!);
  }
  return matches;
}
