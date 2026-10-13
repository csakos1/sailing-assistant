import 'dart:io';

import 'package:args/args.dart';
import 'package:data/data.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/cli/missing_files.dart';
import 'package:web_server/src/polar/polar_reference.dart';
import 'package:web_server/src/polar/polar_setup.dart';
import 'package:web_server/src/polar_lab/archive_copies.dart';
import 'package:web_server/src/polar_lab/archive_sample_collector.dart';
import 'package:web_server/src/polar_lab/frozen_vane_mask.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_build.dart';
import 'package:web_server/src/polar_lab/polar_build_summary.dart';
import 'package:web_server/src/polar_lab/smoothed_polar_grid.dart';
import 'package:web_server/src/polar_lab/steady_wind_mask.dart';

// A polár-builder (docs/PLAN.md P.3, ADR 0058): a webes archívum egy
// mentéséből minden év adatából `.pol`-t épít, és egy markdown-összesítőt
// ír mellé. A fejlesztői gépen fut, nem a VPS-en.
//
// A bemenet a VPS éjszakai mentése (VACUUM INTO / .backup, egyetlen fájl,
// -wal nélkül); élő, WAL-os adatbázist ne adj meg, mert a -wal tartalma
// nem másolódik. A --polar a mostani polár: az STW-korrekciókkal együtt
// töltődik (ahogy a szerveren), és az összesítő ehhez veti össze az újat.
//
// Csak olvas: a két SQLite-fájlt a --work-dir alá másolja, a másolatot
// nyitja meg, és a végén törli. A kimenet a `.pol` és az összesítő; nyers
// minta, időbélyeg, pozíció és versenynév egyikben sincs. Az új polár
// csak az összesítő átnézése után kerül az assetbe (P.6).
//
//   cd apps/web_server && dart run bin/build_polar.dart \
//     --archive <mentés>/archive.sqlite --web-db <mentés>/web.sqlite \
//     --polar ../phone/assets/polars/foretack.pol \
//     --stw-corrections <mentés>/stw-corrections.json \
//     --work-dir <könyvtár elég hellyel> \
//     --out-pol <új.pol> --out-summary <összesítő.md> \
//     [--steady-range 20] [--twa-bandwidth 15] [--min-cell-seconds 120] \
//     [--max-downwind-vmg-ratio 1.3]
//
// Az utolsó négy kapcsoló a hangolásé (ADR 0058 D6, D7); az alapértékük az
// ADR-é (az első futások után pontosítva), és az összesítő kiírja, mivel
// futott.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('archive', help: 'Az archívum SQLite-fájlja (kötelező).')
    ..addOption('web-db', help: 'A webes adatok SQLite-fájlja (kötelező).')
    ..addOption('polar', help: 'A mostani `.pol` fájl (kötelező).')
    ..addOption('stw-corrections', help: 'Az STW-korrekciók JSON-ja.')
    ..addOption(
      'work-dir',
      help: 'A másolatok helye (kötelező, létező könyvtár).',
    )
    ..addOption('out-pol', help: 'Az új `.pol` fájl (kötelező).')
    ..addOption('out-summary', help: 'Az összesítő fájlja (kötelező).')
    ..addOption(
      'steady-range',
      defaultsTo: '20',
      help: 'Az állandósult szél küszöbe: a |TWA| terjedelme ±10 mp-en (fok).',
    )
    ..addOption(
      'twa-bandwidth',
      defaultsTo: '15',
      help: 'A TWA menti simítás sávszélessége (±fok).',
    )
    ..addOption(
      'min-cell-seconds',
      defaultsTo: '120',
      help: 'Ennyi mért idő alatt a cella nem mért (másodperc).',
    )
    ..addOption(
      'max-downwind-vmg-ratio',
      defaultsTo: '1.3',
      help: 'Mély hátszélben a VMG és a TWS legnagyobb aránya.',
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
  // A mostani polár (jellemzően az asset) nem íródhat felül: az új polár
  // csak az összesítő átnézése után, külön commitban kerül a helyére (P.6).
  if (_isSameFile(options.outPolPath, options.polarPath)) {
    stderr.writeln('--out-pol: nem lehet ugyanaz, mint a --polar');
    exitCode = 64;
    return;
  }

  final setup = await loadPolarSetup(
    polarPath: options.polarPath,
    correctionsPath: options.correctionsPath,
  );
  switch (setup) {
    case PolarReady(:final reference):
      await _build(options, reference);
    case PolarMissing(:final reason):
      stderr.writeln(reason);
      exitCode = 66;
  }
}

Future<void> _build(_Options options, PolarReference reference) async {
  final samples = await withArchiveCopies<_Samples>(
    archivePath: options.archivePath,
    webDbPath: options.webDbPath,
    workDirPath: options.workDirPath,
    tempPrefix: 'polar-build-',
    log: stderr.writeln,
    body: (copies) => _collect(copies, reference, options.steadyRangeDegrees),
  );
  final build = PolarBuild.of(
    allSamples: samples.allSamples,
    unfrozenSamples: samples.unfrozenSamples,
    steadySamples: samples.steadySamples,
    parameters: PolarSmoothingParameters(
      minimumMeasuredSeconds: options.minimumCellSeconds,
      twaBandwidthDegrees: options.twaBandwidthDegrees,
    ),
    maximumDownwindVmgRatio: options.maximumDownwindVmgRatio,
  );
  switch (parseForetackPolar(build.polarText)) {
    case Ok(value: final newPolar):
      await File(options.outPolPath).writeAsString(build.polarText);
      stderr.writeln('Polár: ${options.outPolPath}');
      final summary = polarBuildSummary(
        build: build,
        oldPolar: reference.polar,
        newPolar: newPolar,
        oldPolarLabel:
            '${options.polarPath.split('/').last} (${reference.fingerprint})',
        steadyWindRangeDegrees: options.steadyRangeDegrees,
      );
      await File(options.outSummaryPath).writeAsString(summary);
      stderr.writeln('Összesítő: ${options.outSummaryPath}');
    case Err(:final error):
      // A saját kimenetünk nem olvasható vissza: programozói hiba, a fájl
      // nem íródik ki.
      stderr.writeln('Az új polár nem olvasható vissza: $error');
      exitCode = 70;
  }
}

bool _isSameFile(String path, String otherPath) =>
    File(path).absolute.path == File(otherPath).absolute.path ||
    (File(path).existsSync() &&
        FileSystemEntity.identicalSync(path, otherPath));

typedef _Samples = ({
  List<LabSample> allSamples,
  List<LabSample> unfrozenSamples,
  List<LabSample> steadySamples,
});

Future<_Samples> _collect(
  ArchiveCopies copies,
  PolarReference reference,
  double steadyRangeDegrees,
) async {
  final allSamples = await archiveSampleCollector(
    copies,
    corrections: reference.corrections,
    log: stderr.writeln,
  )();
  stderr.writeln('Minták: ${allSamples.length}');
  final unfrozenSamples = await archiveSampleCollector(
    copies,
    corrections: reference.corrections,
    log: stderr.writeln,
    sampleMask: frozenVaneMask,
  )();
  stderr.writeln('Működő szélirány-mérő: ${unfrozenSamples.length}');
  final steadySamples = await archiveSampleCollector(
    copies,
    corrections: reference.corrections,
    log: stderr.writeln,
    sampleMask: (samples) => _bothMasks(
      frozenVaneMask(samples),
      steadyWindMask(samples, maximumRangeDegrees: steadyRangeDegrees),
    ),
  )();
  stderr.writeln('Állandósult szelű minták: ${steadySamples.length}');
  return (
    allSamples: allSamples,
    unfrozenSamples: unfrozenSamples,
    steadySamples: steadySamples,
  );
}

// Két egyforma hosszú maszk metszete: csak az marad, amit mindkettő tart.
List<bool> _bothMasks(List<bool> first, List<bool> second) => [
  for (var index = 0; index < first.length; index++)
    first[index] && second[index],
];

final class _Options {
  const _Options({
    required this.archivePath,
    required this.webDbPath,
    required this.polarPath,
    required this.workDirPath,
    required this.outPolPath,
    required this.outSummaryPath,
    required this.steadyRangeDegrees,
    required this.twaBandwidthDegrees,
    required this.minimumCellSeconds,
    required this.maximumDownwindVmgRatio,
    this.correctionsPath,
  });

  factory _Options.parse(ArgResults results) => _Options(
    archivePath: _required(results, 'archive'),
    webDbPath: _required(results, 'web-db'),
    polarPath: _required(results, 'polar'),
    workDirPath: _required(results, 'work-dir'),
    outPolPath: _required(results, 'out-pol'),
    outSummaryPath: _required(results, 'out-summary'),
    steadyRangeDegrees: _positiveNumber(results, 'steady-range'),
    twaBandwidthDegrees: _positiveNumber(results, 'twa-bandwidth'),
    minimumCellSeconds: _positiveInteger(results, 'min-cell-seconds'),
    maximumDownwindVmgRatio: _positiveNumber(results, 'max-downwind-vmg-ratio'),
    correctionsPath: results.option('stw-corrections'),
  );

  final String archivePath;
  final String webDbPath;
  final String polarPath;
  final String workDirPath;
  final String outPolPath;
  final String outSummaryPath;
  final double steadyRangeDegrees;
  final double twaBandwidthDegrees;
  final int minimumCellSeconds;
  final double maximumDownwindVmgRatio;
  final String? correctionsPath;

  static String _required(ArgResults results, String name) {
    final value = results.option(name);
    if (value == null || value.isEmpty) {
      throw FormatException('--$name: kötelező');
    }
    return value;
  }

  static double _positiveNumber(ArgResults results, String name) {
    final text = results.option(name) ?? '';
    final value = double.tryParse(text);
    if (value == null || !value.isFinite || value <= 0) {
      throw FormatException('--$name: pozitív szám kell: $text');
    }
    return value;
  }

  static int _positiveInteger(ArgResults results, String name) {
    final text = results.option(name) ?? '';
    final value = int.tryParse(text);
    if (value == null || value <= 0) {
      throw FormatException('--$name: pozitív egész kell: $text');
    }
    return value;
  }
}
