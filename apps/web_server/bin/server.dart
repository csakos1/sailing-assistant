import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:web_server/src/export/database_snapshot.dart';
import 'package:web_server/src/export/history_exporter.dart';
import 'package:web_server/src/export/stale_export_cleanup.dart';
import 'package:web_server/src/export/vacuum_into.dart';
import 'package:web_server/src/http/archive_api.dart';
import 'package:web_server/src/http/export_handler.dart';
import 'package:web_server/src/http/import_handler.dart';
import 'package:web_server/src/http/import_upload_receiver.dart';
import 'package:web_server/src/http/manual_race_handler.dart';
import 'package:web_server/src/http/polar_handler.dart';
import 'package:web_server/src/http/race_detail_handler.dart';
import 'package:web_server/src/http/race_list_handler.dart';
import 'package:web_server/src/http/race_result_handler.dart';
import 'package:web_server/src/import/race_importer.dart';
import 'package:web_server/src/polar/legacy_polar_sample_reader.dart';
import 'package:web_server/src/polar/polar_race_catalog.dart';
import 'package:web_server/src/polar/polar_setup.dart';
import 'package:web_server/src/polar/polar_stats_calculator.dart';
import 'package:web_server/src/polar/polar_stats_refresher.dart';
import 'package:web_server/src/polar/polar_table_service.dart';
import 'package:web_server/src/race/archive_read_services.dart';
import 'package:web_server/src/race/manual_race_service.dart';
import 'package:web_server/src/race/race_result_service.dart';
import 'package:web_server/src/serial_lock.dart';
import 'package:web_server/src/stats/legacy_track_stats_refresher.dart';
import 'package:web_server/src/stats/race_stats_calculator.dart';
import 'package:web_server/src/stats/race_stats_refresher.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/polar_stats_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';
import 'package:web_server/src/web_db/web_database.dart';
import 'package:web_server/src/web_server_version.dart';

// A webes archívum REST szervere (ADR 0047 Addendum 3 C5). Kompozíciós
// gyökér: itt, és csak itt, dől el, melyik implementáció áll az
// absztrakciók mögött.
//
//   dart run web_server:server \
//     --archive /var/lib/foretack/archive.sqlite \
//     --web-db /var/lib/foretack/web.sqlite \
//     --polar /var/lib/foretack/foretack.pol \
//     --stw-corrections /var/lib/foretack/stw-corrections.json

const _defaultPort = 8087;
const int _defaultMaxImportBytes = 4 * 1024 * 1024 * 1024;
const int _jsonBodyLimitBytes = 64 * 1024;

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('archive', help: 'Az archívum SQLite-fájlja (kötelező).')
    ..addOption('web-db', help: 'A webes adatok SQLite-fájlja (kötelező).')
    ..addOption(
      'host',
      help: 'A figyelt cím (D9: csak loopback).',
      defaultsTo: '127.0.0.1',
    )
    ..addOption('port', help: 'A figyelt port.', defaultsTo: '$_defaultPort')
    ..addOption(
      'max-import-bytes',
      help: 'A feltöltés felső korlátja bájtban.',
      defaultsTo: '$_defaultMaxImportBytes',
    )
    ..addOption(
      'temp-root',
      help: 'A feltöltések, importok és exportok ideiglenes könyvtára.',
    )
    ..addOption(
      'polar',
      help: 'A phone polárja (foretack.pol); nélküle nincs polár-statisztika.',
    )
    ..addOption(
      'stw-corrections',
      help: 'Az STW-korrekciók JSON-fájlja (ADR 0049 D6); opcionális.',
    );

  final ArgResults options;
  final String archivePath;
  final String webDatabasePath;
  final int port;
  final int maxImportBytes;
  try {
    options = parser.parse(arguments);
    archivePath = _requiredOption(options, 'archive');
    webDatabasePath = _requiredOption(options, 'web-db');
    port = _positiveInt(options, 'port');
    maxImportBytes = _positiveInt(options, 'max-import-bytes');
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(parser.usage);
    exitCode = 64;
    return;
  }

  // A defaultsTo miatt a host a parse után nem lehet null.
  final host = options.option('host')!;
  final tempRootPath = options.option('temp-root');
  final tempRoot = tempRootPath == null
      ? Directory.systemTemp
      : Directory(tempRootPath);

  // Háttér-isolate: a több perces import nem blokkolja az event loopot
  // (C5). Az ATTACH is működik, mert az isolate egyetlen kapcsolatot tart.
  final archive = AppDatabase(
    NativeDatabase.createInBackground(File(archivePath)),
  );
  final webDatabase = WebDatabase(
    NativeDatabase.createInBackground(File(webDatabasePath)),
  );

  final races = RaceRepositoryImpl(archive);
  final results = RaceResultRepository(webDatabase);
  final stats = RaceStatsRepository(webDatabase);
  final manualRaces = ManualRaceRepository(webDatabase);
  final calculate = RaceStatsCalculator(
    readTrackSamples: TrackSampleReaderImpl(archive).readWindow,
    readWindSamples: WindSampleReaderImpl(archive).call,
  );
  final refresher = RaceStatsRefresher(
    races: races,
    results: results,
    stats: stats,
    calculate: calculate,
    log: _log,
  );
  final legacyTracks = LegacyTrackRepository(webDatabase);
  final polarSetup = await loadPolarSetup(
    polarPath: options.option('polar'),
    correctionsPath: options.option('stw-corrections'),
  );
  final polarCatalog = PolarRaceCatalog(
    races: races,
    results: results,
    manualRaces: manualRaces,
    tracks: legacyTracks,
    log: _log,
  );
  final polarRepository = PolarStatsRepository(webDatabase);
  // Polár nélkül nincs frissítő és nincs olvasó szolgáltatás: a
  // végpontok 503-at adnak, a többi működik (ADR 0049 Addendum 4 U1).
  final PolarStatsRefresher? polarRefresher;
  final PolarTableService? polarTables;
  switch (polarSetup) {
    case PolarReady(:final reference):
      polarRefresher = PolarStatsRefresher(
        catalog: polarCatalog,
        repository: polarRepository,
        calculate: PolarStatsCalculator(
          readTelemetrySamples: PolarSampleReaderImpl(archive).call,
          readLegacySamples: LegacyPolarSampleReader(legacyTracks).call,
          reference: reference,
        ),
        log: _log,
      );
      polarTables = PolarTableService(
        catalog: polarCatalog,
        repository: polarRepository,
        fingerprint: reference.fingerprint,
      );
      _log('polár: ${reference.fingerprint}');
    case PolarMissing(:final reason):
      polarRefresher = null;
      polarTables = null;
      _log('polár nem elérhető: $reason');
  }
  Future<void> refreshPolar(String raceId) async {
    await polarRefresher?.refreshIfStale(raceId);
  }

  // A trackes kézi verseny statja a régi trackből, ugyanazzal a számolóval
  // (ADR 0050 D5); a napló az S13b-től adja (Addendum 1 E1).
  final legacyRefresher = LegacyTrackStatsRefresher(
    manualRaces: manualRaces,
    results: results,
    tracks: legacyTracks,
    stats: stats,
    calculate: RaceStatsCalculator(
      readTrackSamples: legacyTracks.readWindow,
      readWindSamples: legacyTracks.readWindow,
    ),
    log: _log,
  );
  // Egy zár az importnak és a mentések utáni frissítésnek (ADR 0048
  // Addendum 3 I5, ADR 0050 Addendum 1 E2).
  final writeLock = SerialLock();
  // A napló és a részletező olvasói; az export a pillanatképre ugyanezeket
  // rakja össze (ADR 0050 Addendum 3 G3).
  final reads = ArchiveReadServices.over(
    archive: archive,
    webDatabase: webDatabase,
    log: _log,
  );
  // Egy korábbi futás félbemaradt exportja (G2); most még nem fut export.
  final staleExports = await removeStaleExportDirectories(tempRoot);
  if (staleExports > 0) _log('árva export-könyvtár törölve: $staleExports');

  final handler = buildArchiveApiHandler(
    raceList: RaceListHandler(reads.summaries),
    raceDetail: RaceDetailHandler(reads.details),
    raceResult: RaceResultHandler(
      service: RaceResultService(
        races: races,
        results: results,
        refresher: refresher,
        lock: writeLock,
        refreshPolar: refreshPolar,
      ),
      bodyLimitBytes: _jsonBodyLimitBytes,
    ),
    manualRaces: ManualRaceHandler(
      service: ManualRaceService(
        manualRaces: manualRaces,
        results: results,
        tracks: legacyTracks,
        stats: stats,
        runInTransaction: webDatabase.transaction,
        lock: writeLock,
        refreshStats: (raceId) async {
          await legacyRefresher.refreshIfStale(raceId);
          await refreshPolar(raceId);
        },
      ),
      bodyLimitBytes: _jsonBodyLimitBytes,
    ),
    imports: ImportHandler(
      importer: RaceImporter(
        archive: archive,
        tempRoot: tempRoot,
        lock: writeLock,
        afterMerge: (report) async {
          await refresher.afterImport(report);
          await polarRefresher?.afterImport(report);
        },
      ),
      receiver: ImportUploadReceiver(limitBytes: maxImportBytes),
      tempRoot: tempRoot,
    ),
    polar: PolarHandler(polarTables),
    export: ExportHandler(
      HistoryExporter(
        tempRoot: tempRoot,
        lock: writeLock,
        snapshotArchive: (path) => vacuumInto(archive, path),
        snapshotWebDatabase: (path) => vacuumInto(webDatabase, path),
        openSnapshot: ({required archiveCopy, required webCopy}) =>
            openDatabaseSnapshot(
              archiveCopy: archiveCopy,
              webCopy: webCopy,
              log: _log,
            ),
        archiveSchemaVersion: archive.schemaVersion,
        webSchemaVersion: webDatabase.schemaVersion,
        serverVersion: webServerVersion,
        log: _log,
      ),
    ),
    log: _log,
  );

  final server = await shelf_io.serve(handler, host, port);
  // A tömörítés a Caddy dolga (C6).
  server.autoCompress = false;
  _log('figyel: http://$host:$port');
  // Egy polár- vagy konfig-csere minden sort érint: a háttérben, a zár
  // alatt frissül, a szerver közben kiszolgál (ADR 0049 Addendum 4 U6).
  final polarRefreshAll = polarRefresher?.refreshAllStale;
  if (polarRefreshAll != null) unawaited(writeLock.run(polarRefreshAll));

  await Future.any([
    ProcessSignal.sigint.watch().first,
    ProcessSignal.sigterm.watch().first,
  ]);
  _log('leállás');
  await server.close();
  await archive.close();
  await webDatabase.close();
}

void _log(String message) => stderr.writeln(message);

// Az args `mandatory` jelzője a hiányt nem a parse-kor, hanem csak az
// érték olvasásakor jelezné, ArgumentError-ral. Így a hiányzó kapcsoló is
// usage-kiírással és 64-es kóddal ér véget, mint a többi hibás kapcsoló.
String _requiredOption(ArgResults options, String name) =>
    options.option(name) ??
    (throw FormatException('--$name: kötelező kapcsoló'));

int _positiveInt(ArgResults options, String name) {
  // A defaultsTo miatt az érték itt nem lehet null.
  final raw = options.option(name)!;
  final value = int.tryParse(raw);
  if (value == null || value < 1) {
    throw FormatException('--$name: pozitív egész kell, kaptam: $raw');
  }
  return value;
}
