import 'dart:io';

import 'package:args/args.dart';
import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:web_server/src/stats/race_stats_calculator.dart';
import 'package:web_server/src/stats/race_stats_refresher.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';
import 'package:web_server/src/web_db/web_database.dart';

// A `race_stats` cache teljes újraszámolása a VPS-en (ADR 0048 Addendum 9
// R4). A sorok képlet-verziót nem hordoznak, ezért egy képlet-változás
// (pl. a max. szél szűrője) után ez frissíti a meglévőket. A szerver
// fusson le előtte, hogy ne írjon két folyamat ugyanabba a fájlba.
//
//   refresh_race_stats \
//     --archive /var/lib/foretack/archive.sqlite \
//     --web-db /var/lib/foretack/web.sqlite
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('archive', help: 'Az archívum SQLite-fájlja (kötelező).')
    ..addOption('web-db', help: 'A webes adatok SQLite-fájlja (kötelező).');

  final String archivePath;
  final String webDatabasePath;
  try {
    final options = parser.parse(arguments);
    archivePath = _requiredOption(options, 'archive');
    webDatabasePath = _requiredOption(options, 'web-db');
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(parser.usage);
    exitCode = 64;
    return;
  }
  for (final path in [archivePath, webDatabasePath]) {
    if (!File(path).existsSync()) {
      stderr.writeln('Nincs ilyen fájl: $path');
      exitCode = 66;
      return;
    }
  }

  final archive = AppDatabase(NativeDatabase(File(archivePath)));
  final webDatabase = WebDatabase(NativeDatabase(File(webDatabasePath)));
  try {
    final refresher = RaceStatsRefresher(
      races: RaceRepositoryImpl(archive),
      results: RaceResultRepository(webDatabase),
      stats: RaceStatsRepository(webDatabase),
      calculate: RaceStatsCalculator(
        readTrackSamples: TrackSampleReaderImpl(archive).readWindow,
        readWindSamples: WindSampleReaderImpl(archive).call,
      ),
      log: stderr.writeln,
    );
    final refreshed = await refresher.refreshAll();
    stdout.writeln('Újraszámolva: $refreshed verseny');
  } finally {
    await archive.close();
    await webDatabase.close();
  }
}

// Ahogy az import_race_db-ben: a hiányzó kötelező kapcsoló usage-kiírással
// és 64-es kóddal ér véget.
String _requiredOption(ArgResults options, String name) =>
    options.option(name) ??
    (throw FormatException('--$name: kötelező kapcsoló'));
