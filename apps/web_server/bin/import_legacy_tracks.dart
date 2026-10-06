import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:drift/native.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/cli/missing_files.dart';
import 'package:web_server/src/legacy/describe_legacy_tracks.dart';
import 'package:web_server/src/legacy/legacy_csv_slice.dart';
import 'package:web_server/src/legacy/legacy_track_applier.dart';
import 'package:web_server/src/legacy/legacy_track_windows.dart';
import 'package:web_server/src/legacy/plan_legacy_tracks.dart';
import 'package:web_server/src/legacy/slice_ydvr_csv.dart';
import 'package:web_server/src/stats/legacy_track_stats_refresher.dart';
import 'package:web_server/src/stats/race_stats_calculator.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/polar_stats_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';
import 'package:web_server/src/web_db/web_database.dart';

// A régi versenyek trackje a YDVR-napló polar.csv-jéből (ADR 0050 D4 +
// Addendum 1 E3, E4). Alapból próbafuttatás: versenyenként kiírja, mi
// kerülne fel, és nem ír semmit. Az --apply a teljes állapotot írja, és
// utána frissíti a statisztikát. A kézi versenyek polár-sorai törlődnek;
// a szerver a következő induláskor újraszámolja őket (ADR 0049 Addendum
// 4 U6). Az Excel-import után fut, mert a hivatalos idők onnan jönnek; a
// szerver fusson le előtte.
//
//   dart run web_server:import_legacy_tracks \
//     --web-db /var/lib/foretack/web.sqlite \
//     --csv polar.csv [--apply]
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('web-db', help: 'A webes adatok SQLite-fájlja (kötelező).')
    ..addOption('csv', help: 'A YDVRCONV polar.csv-je (kötelező).')
    ..addFlag('apply', negatable: false, help: 'A terv végrehajtása.');

  final String webDbPath;
  final String csvPath;
  final bool shouldApply;
  try {
    final options = parser.parse(arguments);
    webDbPath = _requiredOption(options, 'web-db');
    csvPath = _requiredOption(options, 'csv');
    shouldApply = options.flag('apply');
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final missing = missingFileLines({'web-db': webDbPath, 'csv': csvPath});
  if (missing.isNotEmpty) {
    for (final line in missing) {
      stderr.writeln(line);
    }
    exitCode = 66;
    return;
  }

  final webDatabase = WebDatabase(NativeDatabase(File(webDbPath)));
  try {
    await _run(webDatabase, File(csvPath), shouldApply: shouldApply);
  } on FileSystemException catch (error) {
    stderr.writeln('A CSV nem olvasható: $csvPath, ${error.message}');
    exitCode = 66;
  } finally {
    await webDatabase.close();
  }
}

Future<void> _run(
  WebDatabase webDatabase,
  File csv, {
  required bool shouldApply,
}) async {
  final manualRaces = ManualRaceRepository(webDatabase);
  final results = RaceResultRepository(webDatabase);
  final races = await manualRaces.getAll();
  final raceResults = await results.getAll();
  final windows = legacyTrackWindowsOf(
    manualRaces: races,
    results: raceResults,
  );
  // Ablak nélkül is végigmegy: az --apply ekkor a korábbi trackeket
  // törli, így a teljes állapot ilyenkor is a mostani (E4).
  if (windows.isEmpty) {
    stdout.writeln('Nincs hivatalos idős kézi verseny: track nem kerül fel.');
  }

  // A hibás bájt U+FFFD lesz; ha egy használt cellába esik, a sor hibás
  // sorként kimarad (E3).
  final lines = csv
      .openRead()
      .transform(const Utf8Decoder(allowMalformed: true))
      .transform(const LineSplitter());
  final LegacyCsvSlice slice;
  switch (await sliceYdvrCsv(lines, windows)) {
    case Ok(:final value):
      slice = value;
    case Err(:final error):
      describeYdvrCsvHeaderError(error).forEach(stderr.writeln);
      exitCode = 1;
      return;
  }

  final plan = planLegacyTracks(
    manualRaces: races,
    results: raceResults,
    tracks: slice.tracks,
  );
  for (final line in describeLegacyTracks(slice, plan)) {
    stdout.writeln(line);
  }
  if (!shouldApply) {
    stdout.writeln('Próbafuttatás: semmi nem íródott. Írás: --apply.');
    return;
  }

  final tracks = LegacyTrackRepository(webDatabase);
  final refresher = LegacyTrackStatsRefresher(
    manualRaces: manualRaces,
    results: results,
    tracks: tracks,
    stats: RaceStatsRepository(webDatabase),
    calculate: RaceStatsCalculator(
      readTrackSamples: tracks.readWindow,
      readWindSamples: tracks.readWindow,
    ),
    log: stderr.writeln,
  );
  final report = await LegacyTrackApplier(
    tracks: tracks,
    runInTransaction: webDatabase.transaction,
    refreshStats: () async {
      await refresher.refreshAll();
      await PolarStatsRepository(
        webDatabase,
      ).deleteAll([for (final race in races) race.id]);
    },
  )(plan);
  stdout.writeln('--- Végrehajtva ---');
  for (final line in describeLegacyTrackApply(report)) {
    stdout.writeln(line);
  }
}

// Az import_race_db mintája (ADR 0048 Addendum 3 I8).
String _requiredOption(ArgResults options, String name) =>
    options.option(name) ??
    (throw FormatException('--$name: kötelező kapcsoló'));
