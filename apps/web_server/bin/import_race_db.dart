import 'dart:io';

import 'package:args/args.dart';
import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/import/race_importer.dart';

// CLI-import közvetlenül a VPS-en (ADR 0047 Addendum 2 B4): ugyanaz a
// RaceImporter, mint a HTTP-végpont mögött. Tesztekhez és vészhelyzetre.
//
//   dart run web_server:import_race_db \
//     --archive /var/lib/foretack/archive.sqlite \
//     --database foretack.sqlite [--wal foretack.sqlite-wal]
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('archive', help: 'Az archívum SQLite-fájlja.', mandatory: true)
    ..addOption(
      'database',
      help: 'A lehúzott foretack.sqlite.',
      mandatory: true,
    )
    ..addOption('wal', help: 'Az opcionális foretack.sqlite-wal.');

  final ArgResults options;
  try {
    options = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(parser.usage);
    exitCode = 64;
    return;
  }

  // A mandatory opciók a parse után nem lehetnek null-ok (az args dob, ha
  // hiányoznak), ezért a `!` itt nem bukhat el.
  final archive = AppDatabase(NativeDatabase(File(options.option('archive')!)));
  final walPath = options.option('wal');
  try {
    final result = await RaceImporter(archive: archive)(
      database: File(options.option('database')!),
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
  }
}

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
