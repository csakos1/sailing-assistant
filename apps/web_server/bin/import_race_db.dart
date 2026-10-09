import 'dart:io';

import 'package:args/args.dart';
import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/import/race_importer.dart';
import 'package:web_server/src/stats/race_stats_calculator.dart';
import 'package:web_server/src/stats/race_stats_refresher.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';
import 'package:web_server/src/web_db/web_database.dart';

// CLI-import közvetlenül a VPS-en (ADR 0047 Addendum 2 B4): ugyanaz a
// RaceImporter és ugyanaz a statisztika-frissítés, mint a HTTP-végpont
// mögött (ADR 0048 Addendum 3 I8). Tesztekhez és vészhelyzetre; a szerver
// fusson le előtte, hogy ne írjon két folyamat ugyanabba a fájlba.
//
//   dart run web_server:import_race_db \
//     --archive /var/lib/foretack/archive.sqlite \
//     --web-db /var/lib/foretack/web.sqlite \
//     --database foretack.sqlite [--wal foretack.sqlite-wal]
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('archive', help: 'Az archívum SQLite-fájlja (kötelező).')
    ..addOption('web-db', help: 'A webes adatok SQLite-fájlja (kötelező).')
    ..addOption('database', help: 'A lehúzott foretack.sqlite (kötelező).')
    ..addOption('wal', help: 'Az opcionális foretack.sqlite-wal.');

  final String archivePath;
  final String webDatabasePath;
  final String databasePath;
  final String? walPath;
  try {
    final options = parser.parse(arguments);
    archivePath = _requiredOption(options, 'archive');
    webDatabasePath = _requiredOption(options, 'web-db');
    databasePath = _requiredOption(options, 'database');
    walPath = options.option('wal');
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final archive = AppDatabase(NativeDatabase(File(archivePath)));
  final webDatabase = WebDatabase(NativeDatabase(File(webDatabasePath)));
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
  try {
    final importer = RaceImporter(
      archive: archive,
      afterMerge: refresher.afterImport,
    );
    final result = await importer(
      database: File(databasePath),
      wal: walPath == null ? null : File(walPath),
    );
    switch (result) {
      case Ok(value: final report):
        _printReport(report);
      case Err(error: final rejection):
        stderr.writeln('Elutasítva: ${_describe(rejection)}');
        exitCode = 1;
    }
  } finally {
    await archive.close();
    await webDatabase.close();
  }
}

// A szerver mintája: a hiányzó kötelező kapcsoló is usage-kiírással és
// 64-es kóddal ér véget. Az args `mandatory` jelzője a hiányt csak az érték
// olvasásakor jelezné, ArgumentError-ral (Addendum 3 I8).
String _requiredOption(ArgResults options, String name) =>
    options.option(name) ??
    (throw FormatException('--$name: kötelező kapcsoló'));

void _printReport(ImportReport report) {
  void section(String title, Iterable<String> lines) {
    stdout.writeln('$title: ${lines.length}');
    for (final line in lines) {
      stdout.writeln('  $line');
    }
  }

  section('Új', report.added.map((race) => race.name));
  section('Frissítve', report.updated.map((race) => race.name));
  section(
    'Kihagyva (nem befejezett)',
    report.skipped.map((race) => '${race.name} (${race.status.name})'),
  );
  for (final warning in report.warnings) {
    stdout.writeln('Figyelmeztetés: ${warning.name}');
  }
}

String _describe(ImportRejection rejection) => switch (rejection) {
  MainFileMissing() => 'a fő adatbázis-fájl nem található',
  NotSqliteDatabase() => 'nem SQLite-fájl, vagy sérült',
  NotForetackDatabase() => 'nem Foretack-adatbázis',
  SchemaTooNew(:final fileVersion, :final serverVersion) =>
    'a fájl sémája v$fileVersion, a szerveré v$serverVersion — '
        'frissítsd és deployold a szervert',
};
