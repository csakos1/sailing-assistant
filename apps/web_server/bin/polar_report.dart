import 'dart:io';

import 'package:args/args.dart';
import 'package:web_server/src/cli/missing_files.dart';
import 'package:web_server/src/polar/polar_reference.dart';
import 'package:web_server/src/polar/polar_setup.dart';
import 'package:web_server/src/polar_lab/archive_copies.dart';
import 'package:web_server/src/polar_lab/archive_sample_collector.dart';
import 'package:web_server/src/polar_lab/lab_sample_collector.dart';
import 'package:web_server/src/polar_lab/polar_lab_report.dart';

// A polár-elemzés riportja (docs/PLAN.md P.1): a mai polár és a rögzített
// adat összevetése a webes archívum egy mentéséből. A fejlesztői gépen fut,
// nem a VPS-en.
//
// A bemenet a VPS éjszakai mentése (VACUUM INTO / .backup, egyetlen fájl,
// -wal nélkül); élő, WAL-os adatbázist ne adj meg, mert a -wal tartalma
// nem másolódik.
//
// Csak olvas: a két SQLite-fájlt a --work-dir alá másolja, a másolatot
// nyitja meg (a phone DB megnyitáskor WAL-ra állít), és a végén törli. A
// kimenet összesített markdown: nyers minta, időbélyeg, pozíció és
// versenynév nincs benne. A riport soha nem kerül a repóba.
//
//   cd apps/web_server && dart run bin/polar_report.dart \
//     --archive <mentés>/archive.sqlite --web-db <mentés>/web.sqlite \
//     --polar ../phone/assets/polars/foretack.pol \
//     --stw-corrections <mentés>/stw-corrections.json \
//     --work-dir <könyvtár elég hellyel> [--season 2026] [--out <riport.md>]
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('archive', help: 'Az archívum SQLite-fájlja (kötelező).')
    ..addOption('web-db', help: 'A webes adatok SQLite-fájlja (kötelező).')
    ..addOption('polar', help: 'A `.pol` fájl (kötelező).')
    ..addOption('stw-corrections', help: 'Az STW-korrekciók JSON-ja.')
    ..addOption(
      'work-dir',
      help: 'A másolatok helye (kötelező, létező könyvtár).',
    )
    ..addOption('season', defaultsTo: '2026', help: 'A fókusz-szezon.')
    ..addOption('out', help: 'A riport fájlja; nélküle a standard kimenet.');

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

  final missing = missingFileLines({
    'archive': options.archivePath,
    'web-db': options.webDbPath,
    'polar': options.polarPath,
    if (options.correctionsPath case final String path) 'stw-corrections': path,
  });
  if (!Directory(options.workDirPath).existsSync()) {
    missing.add('--work-dir: a könyvtár nem létezik: ${options.workDirPath}');
  }
  if (missing.isNotEmpty) {
    missing.forEach(stderr.writeln);
    exitCode = 66;
    return;
  }

  final setup = await loadPolarSetup(
    polarPath: options.polarPath,
    correctionsPath: options.correctionsPath,
  );
  switch (setup) {
    case PolarReady(:final reference):
      await _runOnCopies(options, reference);
    case PolarMissing(:final reason):
      stderr.writeln(reason);
      exitCode = 66;
  }
}

Future<void> _runOnCopies(_Options options, PolarReference reference) async {
  final report = await withArchiveCopies<String>(
    archivePath: options.archivePath,
    webDbPath: options.webDbPath,
    workDirPath: options.workDirPath,
    tempPrefix: 'polar-report-',
    log: stderr.writeln,
    body: (copies) => _report(
      copies: copies,
      reference: reference,
      focusSeason: options.season,
      polarLabel:
          '${options.polarPath.split('/').last} (${reference.fingerprint})',
    ),
  );
  final outPath = options.outPath;
  if (outPath == null) {
    stdout.write(report);
  } else {
    await File(outPath).writeAsString(report);
    stderr.writeln('Riport: $outPath');
  }
}

Future<String> _report({
  required ArchiveCopies copies,
  required PolarReference reference,
  required int focusSeason,
  required String polarLabel,
}) async {
  LabSampleCollector collector({required int windMedianHalfWindowSeconds}) =>
      archiveSampleCollector(
        copies,
        corrections: reference.corrections,
        log: stderr.writeln,
        windMedianHalfWindowSeconds: windMedianHalfWindowSeconds,
      );
  final samples = await collector(windMedianHalfWindowSeconds: 0)();
  stderr.writeln('Minták: ${samples.length}');
  // A ±5 mp-es medián a régi napló 10 mp-es mediánjához illeszkedik (P.1b).
  final smoothedSamples = await collector(windMedianHalfWindowSeconds: 5)();
  stderr.writeln('Simított minták: ${smoothedSamples.length}');
  return polarLabReport(
    samples: samples,
    polar: reference.polar,
    focusSeason: focusSeason,
    polarLabel: polarLabel,
    smoothedSamples: smoothedSamples,
  );
}

final class _Options {
  const _Options({
    required this.archivePath,
    required this.webDbPath,
    required this.polarPath,
    required this.workDirPath,
    required this.season,
    this.correctionsPath,
    this.outPath,
  });

  factory _Options.parse(ArgResults results) {
    final seasonText = results.option('season') ?? '';
    final season = int.tryParse(seasonText);
    if (season == null) {
      throw FormatException('--season: évszám kell: $seasonText');
    }
    return _Options(
      archivePath: _required(results, 'archive'),
      webDbPath: _required(results, 'web-db'),
      polarPath: _required(results, 'polar'),
      workDirPath: _required(results, 'work-dir'),
      season: season,
      correctionsPath: results.option('stw-corrections'),
      outPath: results.option('out'),
    );
  }

  final String archivePath;
  final String webDbPath;
  final String polarPath;
  final String workDirPath;
  final int season;
  final String? correctionsPath;
  final String? outPath;

  static String _required(ArgResults results, String name) {
    final value = results.option(name);
    if (value == null || value.isEmpty) {
      throw FormatException('--$name: kötelező');
    }
    return value;
  }
}
