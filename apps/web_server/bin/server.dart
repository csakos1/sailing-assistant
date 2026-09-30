import 'dart:io';

import 'package:args/args.dart';
import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:web_server/src/annotation/annotation_repository.dart';
import 'package:web_server/src/annotation/web_database.dart';
import 'package:web_server/src/http/annotation_handler.dart';
import 'package:web_server/src/http/archive_api.dart';
import 'package:web_server/src/http/import_handler.dart';
import 'package:web_server/src/http/import_upload_receiver.dart';
import 'package:web_server/src/http/race_detail_handler.dart';
import 'package:web_server/src/http/race_list_handler.dart';
import 'package:web_server/src/import/race_importer.dart';
import 'package:web_server/src/race/race_detail_service.dart';
import 'package:web_server/src/race/race_list_service.dart';
import 'package:web_server/src/track_stats/missing_track_stats_backfill.dart';

// A webes archívum REST szervere (ADR 0047 Addendum 3 C5). Kompozíciós
// gyökér: itt, és csak itt, dől el, melyik implementáció áll az
// absztrakciók mögött.
//
//   dart run web_server:server \
//     --archive /var/lib/foretack/archive.sqlite \
//     --annotations /var/lib/foretack/annotations.sqlite

const _defaultPort = 8087;
const int _defaultMaxImportBytes = 4 * 1024 * 1024 * 1024;
const int _annotationBodyLimitBytes = 64 * 1024;

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('archive', help: 'Az archívum SQLite-fájlja (kötelező).')
    ..addOption('annotations', help: 'Az annotációk SQLite-fájlja (kötelező).')
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
      help: 'A feltöltések és importok ideiglenes könyvtára.',
    );

  final ArgResults options;
  final String archivePath;
  final String annotationsPath;
  final int port;
  final int maxImportBytes;
  try {
    options = parser.parse(arguments);
    archivePath = _requiredOption(options, 'archive');
    annotationsPath = _requiredOption(options, 'annotations');
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
    NativeDatabase.createInBackground(File(annotationsPath)),
  );

  final races = RaceRepositoryImpl(archive);
  final annotations = AnnotationRepository(webDatabase);
  final handler = buildArchiveApiHandler(
    raceList: RaceListHandler(
      RaceListService(
        races: races,
        readTrackStats: RaceTrackStatsRepositoryImpl(archive).read,
        readTrackSamples: TrackSampleReaderImpl(archive).call,
        annotations: annotations,
        log: _log,
      ),
    ),
    raceDetail: RaceDetailHandler(
      RaceDetailService(
        races: races,
        readRoundingSamples: RoundingSampleReaderImpl(archive).call,
        annotations: annotations,
      ),
    ),
    annotation: AnnotationHandler(
      races: races,
      annotations: annotations,
      bodyLimitBytes: _annotationBodyLimitBytes,
    ),
    imports: ImportHandler(
      importer: RaceImporter(
        archive: archive,
        tempRoot: tempRoot,
        backfill: MissingTrackStatsBackfill(archive: archive, log: _log),
      ),
      receiver: ImportUploadReceiver(limitBytes: maxImportBytes),
      tempRoot: tempRoot,
    ),
    log: _log,
  );

  final server = await shelf_io.serve(handler, host, port);
  // A tömörítés a Caddy dolga (C6).
  server.autoCompress = false;
  _log('figyel: http://$host:$port');

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
