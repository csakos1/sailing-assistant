import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:web_server/src/http/archive_api.dart';
import 'package:web_server/src/http/import_handler.dart';
import 'package:web_server/src/http/import_upload_receiver.dart';
import 'package:web_server/src/http/manual_race_handler.dart';
import 'package:web_server/src/http/race_detail_handler.dart';
import 'package:web_server/src/http/race_list_handler.dart';
import 'package:web_server/src/http/race_result_handler.dart';
import 'package:web_server/src/import/race_importer.dart';
import 'package:web_server/src/race/manual_race_service.dart';
import 'package:web_server/src/race/race_detail_service.dart';
import 'package:web_server/src/race/race_result_service.dart';
import 'package:web_server/src/race/race_summary_service.dart';
import 'package:web_server/src/serial_lock.dart';
import 'package:web_server/src/stats/race_stats_calculator.dart';
import 'package:web_server/src/stats/race_stats_refresher.dart';
import 'package:web_server/src/stats/telemetry_stats_resolver.dart';
import 'package:web_server/src/web_db/cached_race_stats.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';

import '../support/archive_fixture.dart';

// Handler-szintu tesztek: valodi shelf Request-ek a teljes pipeline-on at
// (naplo, kivetelfogo, fejlec-or, router), socket nelkul, valodi
// ideiglenes DB-kkel. A fixture versenyeinek harom pozicios mintaja SOG
// 3, 4, 5 m/s, masodpercenkent a rajttol.

const _boundary = 'foretack-test-boundary';
const Map<String, String> _webClient = {clientHeaderName: clientHeaderWebValue};

void main() {
  late ArchiveDatabases databases;
  late Directory uploadRoot;
  late Handler handler;
  late List<String> logLines;
  late int idCounter;
  final now = DateTime.utc(2026, 10, 1, 8, 30);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  Handler buildHandler({
    int importLimitBytes = 8 * 1024 * 1024,
    int jsonLimitBytes = 1024,
  }) {
    final archive = databases.archive;
    final web = databases.web;
    final races = RaceRepositoryImpl(archive);
    final results = RaceResultRepository(web);
    final stats = RaceStatsRepository(web);
    final manualRaces = ManualRaceRepository(web);
    final calculate = RaceStatsCalculator(
      readTrackSamples: TrackSampleReaderImpl(archive).readWindow,
      readWindSamples: WindSampleReaderImpl(archive).call,
      now: () => now,
    );
    final resolveStats = TelemetryStatsResolver(
      calculate: calculate,
      log: logLines.add,
    );
    final refresher = RaceStatsRefresher(
      races: races,
      results: results,
      stats: stats,
      calculate: calculate,
      log: logLines.add,
    );
    final lock = SerialLock();
    return buildArchiveApiHandler(
      raceList: RaceListHandler(
        RaceSummaryService(
          races: races,
          results: results,
          stats: stats,
          manualRaces: manualRaces,
          resolveStats: resolveStats,
          log: logLines.add,
        ),
      ),
      raceDetail: RaceDetailHandler(
        RaceDetailService(
          races: races,
          readRoundingSamples: RoundingSampleReaderImpl(archive).call,
          results: results,
          stats: stats,
          manualRaces: manualRaces,
          resolveStats: resolveStats,
          log: logLines.add,
        ),
      ),
      raceResult: RaceResultHandler(
        service: RaceResultService(
          races: races,
          results: results,
          refresher: refresher,
          lock: lock,
          now: () => now,
        ),
        bodyLimitBytes: jsonLimitBytes,
      ),
      manualRaces: ManualRaceHandler(
        service: ManualRaceService(
          manualRaces: manualRaces,
          results: results,
          tracks: LegacyTrackRepository(web),
          stats: stats,
          runInTransaction: web.transaction,
          lock: lock,
          // A regi track frissitoje a sajat tesztjeben (ADR 0050 E2).
          refreshStats: (_) async {},
          newId: () => 'manual-${++idCounter}',
          now: () => now,
        ),
        bodyLimitBytes: jsonLimitBytes,
      ),
      imports: ImportHandler(
        importer: RaceImporter(
          archive: archive,
          tempRoot: uploadRoot,
          lock: lock,
          afterMerge: refresher.afterImport,
        ),
        receiver: ImportUploadReceiver(limitBytes: importLimitBytes),
        tempRoot: uploadRoot,
      ),
      log: logLines.add,
    );
  }

  setUp(() async {
    databases = await ArchiveDatabases.open();
    uploadRoot = await Directory(
      '${databases.directory.path}/uploads',
    ).create();
    logLines = [];
    idCounter = 0;
    handler = buildHandler();
  });

  tearDown(() => databases.close());

  Future<Response> send(
    String method,
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) async => handler(
    Request(
      method,
      Uri.parse('http://localhost$path'),
      body: body,
      headers: headers,
    ),
  );

  Future<Object?> jsonOf(Response response) async =>
      jsonDecode(await response.readAsString());

  T unwrap<T>(Result<T, DecodeError> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw StateError('Ok-t vartunk: $error'),
  };

  Future<ApiError> errorOf(Response response) async =>
      unwrap(decodeApiError(await jsonOf(response)));

  Future<Response> putResult(String raceId, Object? json) => send(
    'PUT',
    raceResultPath(raceId),
    body: jsonEncode(json),
    headers: _webClient,
  );

  ManualRaceRequest lelleRequest({
    String name = 'IX. Lelle Kupa',
    RaceResultInput result = const RaceResultInput(),
  }) => ManualRaceRequest(
    race: ManualRaceInput(
      name: name,
      date: CalendarDate.tryParse('2026-07-30')!,
      distanceMeters: 9800,
      windPoint: CompassPoint.southEast,
    ),
    result: result,
  );

  Future<Response> postManual(Object? json) => send(
    'POST',
    manualRacesPath,
    body: jsonEncode(json),
    headers: _webClient,
  );

  Future<Response> putManual(String id, Object? json) => send(
    'PUT',
    manualRacePath(id),
    body: jsonEncode(json),
    headers: _webClient,
  );

  Future<List<RaceSummary>> listRaces() async =>
      unwrap(decodeRaceSummaries(await jsonOf(await send('GET', racesPath))));

  group('GET $racesPath', () {
    test('lists telemetry and manual races newest first', () async {
      // ARRANGE: old 07-26, manual 07-30 noon, new 08-02
      await seedArchiveRace(databases.archive, finishedArchiveRace('old'));
      await seedArchiveRace(
        databases.archive,
        finishedArchiveRace('new', offset: const Duration(days: 7)),
      );
      await postManual(encodeManualRaceRequest(lelleRequest()));
      await putResult('old', {'overallPlace': 3, 'overallFleetSize': 24});

      // ACT
      final summaries = await listRaces();

      // ASSERT
      expect(summaries.map((summary) => summary.id), [
        'new',
        'manual-1',
        'old',
      ]);
      expect(summaries.last.result?.content.overallPlace, const FinishPlace(3));
      expect(summaries[1].origin, isA<ManualOrigin>());
    });

    test('computes a missing stats row in memory without writing it', () async {
      // ARRANGE
      await seedArchiveRace(databases.archive, finishedArchiveRace('r1'));

      // ACT
      final summaries = await listRaces();

      // ASSERT
      final stats = summaries.single.stats;
      expect(stats.window, isA<RecordingWindow>());
      expect(stats.track.maxSpeedMps, 5);
      expect(stats.windPoint, CompassPoint.southWest);
      expect(await RaceStatsRepository(databases.web).get('r1'), isNull);
      expect(
        logLines.where((line) => line.contains('race_stats')),
        hasLength(1),
      );
    });

    test('serves a fresh stats row from the cache', () async {
      // ARRANGE: a deliberately wrong but fresh row proves the cache is used
      final race = finishedArchiveRace('r1');
      await seedArchiveRace(databases.archive, race);
      // A fixture versenye elindult es befejezodott, a ket ido nem null.
      await RaceStatsRepository(databases.web).put(
        'r1',
        CachedRaceStats(
          window: RecordingWindow(
            TimeWindow(start: race.startedAt!, end: race.finishedAt!),
          ),
          track: const TrackStats(maxSpeedMps: 99),
          wind: const WindStats(),
          computedAt: now,
        ),
      );

      // ACT
      final summaries = await listRaces();

      // ASSERT
      expect(summaries.single.stats.track.maxSpeedMps, 99);
      expect(logLines.where((line) => line.contains('race_stats')), isEmpty);
    });
  });

  group('GET $racesPath/{id}', () {
    test('returns a telemetry race with its positioned track', () async {
      // ARRANGE
      await seedArchiveRace(databases.archive, finishedArchiveRace('r1'));

      // ACT
      final response = await send('GET', racePath('r1'));

      // ASSERT
      expect(response.statusCode, 200);
      final detail = unwrap(decodeRaceDetail(await jsonOf(response)));
      expect(detail.summary.id, 'r1');
      expect(detail.summary.stats.track.maxSpeedMps, 5);
      // Harom pozicios minta, a pozicio nelkuli kimarad.
      expect(detail.telemetry?.trackPoints, hasLength(3));
      expect(detail.telemetry?.trackPoints.last.sogMps, 5);
    });

    test('returns a manual race without telemetry', () async {
      // ARRANGE
      await postManual(encodeManualRaceRequest(lelleRequest()));

      // ACT
      final response = await send('GET', racePath('manual-1'));

      // ASSERT
      expect(response.statusCode, 200);
      final detail = unwrap(decodeRaceDetail(await jsonOf(response)));
      expect(detail.summary.name, 'IX. Lelle Kupa');
      expect(detail.telemetry, isNull);
    });

    test('answers 404 for an unknown race', () async {
      final response = await send('GET', racePath('missing'));

      expect(response.statusCode, 404);
      expect(await errorOf(response), const RaceNotFound('missing'));
    });
  });

  group('PUT result', () {
    setUp(() => seedArchiveRace(databases.archive, finishedArchiveRace('r1')));

    test('saves a normalized result and returns it', () async {
      // ACT
      final response = await putResult('r1', {
        'overallPlace': 'dnf',
        'overallFleetSize': 24,
        'prize': '  erem  ',
      });

      // ASSERT
      expect(response.statusCode, 200);
      final result = unwrap(decodeRaceResult(await jsonOf(response)));
      expect(result.content.overallPlace, const Dnf());
      expect(result.content.prize, 'erem');
      expect(
        (await RaceResultRepository(databases.web).get('r1'))?.content,
        result.content,
      );
    });

    test('moves the stats to the official window', () async {
      // ARRANGE: the official window holds the 2nd and 3rd sample only
      final start = archiveStart.add(const Duration(seconds: 1));
      final finish = archiveStart.add(const Duration(seconds: 2));

      // ACT
      await putResult(
        'r1',
        encodeRaceResultInput(
          RaceResultInput(officialStart: start, officialFinish: finish),
        ),
      );

      // ASSERT
      final cached = await RaceStatsRepository(databases.web).get('r1');
      expect(
        cached?.window,
        OfficialWindow(TimeWindow(start: start, end: finish)),
      );
      expect(cached?.track.avgSpeedMps, 4.5);
    });

    test('deletes the result when every field is empty', () async {
      // ARRANGE
      await putResult('r1', {'overallPlace': 3});

      // ACT
      final response = await putResult('r1', <String, Object?>{});

      // ASSERT
      expect(response.statusCode, 200);
      final result = unwrap(decodeRaceResult(await jsonOf(response)));
      expect(result.content.isEmpty, isTrue);
      expect(result.updatedAt, now);
      expect(await RaceResultRepository(databases.web).get('r1'), isNull);
    });

    test('rejects every violation at once with 422', () async {
      // ACT
      final response = await putResult('r1', {
        'classPlace': 10,
        'classFleetSize': 9,
        'overallPlace': 0,
      });

      // ASSERT
      expect(response.statusCode, 422);
      expect(
        await errorOf(response),
        const ValidationFailed([
          PlaceExceedsFleetSize(InputField.classPlace),
          ValueNotPositive(InputField.overallPlace),
        ]),
      );
    });

    test('rejects a body that is not JSON with 400', () async {
      final response = await send(
        'PUT',
        raceResultPath('r1'),
        body: '{nem json',
        headers: _webClient,
      );

      expect(response.statusCode, 400);
      expect(
        await errorOf(response),
        const MalformedRequest(
          DecodeError(path: r'$', expected: 'UTF-8 JSON document'),
        ),
      );
    });

    test('rejects an unknown placing symbol with 400', () async {
      final response = await putResult('r1', {'overallPlace': 'harmadik'});

      expect(response.statusCode, 400);
      expect(
        await errorOf(response),
        const MalformedRequest(
          DecodeError(
            path: r'$.overallPlace',
            expected: 'integer, "dnf", "dsq" or null',
          ),
        ),
      );
    });

    test('answers 404 for an unknown race', () async {
      final response = await putResult('missing', {'overallPlace': 3});

      expect(response.statusCode, 404);
      expect(await errorOf(response), const RaceNotFound('missing'));
    });

    test('answers 404 for a manual race id', () async {
      // ARRANGE
      await postManual(encodeManualRaceRequest(lelleRequest()));

      // ACT
      final response = await putResult('manual-1', {'overallPlace': 3});

      // ASSERT
      expect(response.statusCode, 404);
    });

    test('rejects an oversized body with 413', () async {
      final response = await putResult('r1', {'summary': 'x' * 2000});

      expect(response.statusCode, 413);
      expect(await errorOf(response), const PayloadTooLarge(1024));
    });

    test('requires the client header', () async {
      final response = await send(
        'PUT',
        raceResultPath('r1'),
        body: jsonEncode({'overallPlace': 3}),
      );

      expect(response.statusCode, 403);
      expect(await errorOf(response), const MissingClientHeader());
      expect(await RaceResultRepository(databases.web).get('r1'), isNull);
    });
  });

  group('manual races', () {
    test('POST creates a race with its result and answers 201', () async {
      // ACT
      final response = await postManual(
        encodeManualRaceRequest(
          lelleRequest(
            result: const RaceResultInput(
              overallPlace: FinishPlace(3),
              overallFleetSize: 22,
            ),
          ),
        ),
      );

      // ASSERT
      expect(response.statusCode, 201);
      final summary = unwrap(decodeRaceSummary(await jsonOf(response)));
      expect(summary.id, 'manual-1');
      expect(summary.stats.window, const ManualEntry());
      expect(summary.result?.content.overallFleetSize, 22);
      expect((await listRaces()).single.id, 'manual-1');
    });

    test('POST rejects every violation of both parts with 422', () async {
      // ARRANGE
      final json = encodeManualRaceRequest(
        lelleRequest(
          name: '  ',
          result: const RaceResultInput(ysNumberHundredths: 0),
        ),
      );
      (json['race']! as Map<String, Object?>)['distanceMeters'] = -1;

      // ACT
      final response = await postManual(json);

      // ASSERT
      expect(response.statusCode, 422);
      expect(
        await errorOf(response),
        const ValidationFailed([
          ValueEmpty(InputField.name),
          ValueNegative(InputField.distanceMeters),
          ValueNotPositive(InputField.ysNumberHundredths),
        ]),
      );
      expect(await listRaces(), isEmpty);
    });

    test('POST rejects a malformed date with 400', () async {
      // ARRANGE
      final json = encodeManualRaceRequest(lelleRequest());
      (json['race']! as Map<String, Object?>)['date'] = '2026.07.30';

      // ACT
      final response = await postManual(json);

      // ASSERT
      expect(response.statusCode, 400);
    });

    test('PUT updates the race and replaces its result', () async {
      // ARRANGE
      await postManual(
        encodeManualRaceRequest(
          lelleRequest(
            result: const RaceResultInput(overallPlace: FinishPlace(3)),
          ),
        ),
      );

      // ACT
      final response = await putManual(
        'manual-1',
        encodeManualRaceRequest(lelleRequest(name: 'X. Lelle Kupa')),
      );

      // ASSERT
      expect(response.statusCode, 200);
      final summary = unwrap(decodeRaceSummary(await jsonOf(response)));
      expect(summary.name, 'X. Lelle Kupa');
      expect(summary.result, isNull);
      expect(await RaceResultRepository(databases.web).get('manual-1'), isNull);
    });

    test('PUT answers 404 for an unknown or a telemetry race', () async {
      // ARRANGE
      await seedArchiveRace(databases.archive, finishedArchiveRace('r1'));
      final body = encodeManualRaceRequest(lelleRequest());

      // ACT
      final unknown = await putManual('missing', body);
      final telemetry = await putManual('r1', body);

      // ASSERT
      expect(unknown.statusCode, 404);
      expect(telemetry.statusCode, 404);
    });

    test('DELETE removes the race with its result and answers 204', () async {
      // ARRANGE
      await postManual(
        encodeManualRaceRequest(
          lelleRequest(
            result: const RaceResultInput(overallPlace: FinishPlace(3)),
          ),
        ),
      );

      // ACT
      final response = await send(
        'DELETE',
        manualRacePath('manual-1'),
        headers: _webClient,
      );

      // ASSERT
      expect(response.statusCode, 204);
      expect(await response.readAsString(), isEmpty);
      expect(await RaceResultRepository(databases.web).get('manual-1'), isNull);
      expect((await send('GET', racePath('manual-1'))).statusCode, 404);
    });

    test('DELETE answers 404 for a telemetry race and keeps it', () async {
      // ARRANGE
      await seedArchiveRace(databases.archive, finishedArchiveRace('r1'));

      // ACT
      final response = await send(
        'DELETE',
        manualRacePath('r1'),
        headers: _webClient,
      );

      // ASSERT
      expect(response.statusCode, 404);
      expect((await send('GET', racePath('r1'))).statusCode, 200);
    });

    test('DELETE requires the client header', () async {
      // ARRANGE
      await postManual(encodeManualRaceRequest(lelleRequest()));

      // ACT
      final response = await send('DELETE', manualRacePath('manual-1'));

      // ASSERT
      expect(response.statusCode, 403);
      expect((await listRaces()).single.id, 'manual-1');
    });
  });

  group('POST $importsPath', () {
    Future<List<int>> phoneDatabaseBytes() async {
      final file = File('${databases.directory.path}/phone.sqlite');
      final phone = AppDatabase(NativeDatabase(file));
      await seedArchiveRace(phone, finishedArchiveRace('imported'));
      await phone.close();
      return file.readAsBytes();
    }

    Future<Response> postImport(List<(String, List<int>)> fields) => send(
      'POST',
      importsPath,
      body: _multipartBody(fields),
      headers: {
        ..._webClient,
        'content-type': 'multipart/form-data; boundary=$_boundary',
      },
    );

    test('imports the uploaded database and cleans up the upload', () async {
      // ARRANGE
      final bytes = await phoneDatabaseBytes();

      // ACT
      final response = await postImport([(importDatabaseField, bytes)]);

      // ASSERT
      expect(response.statusCode, 200);
      final report = switch (decodeImportReport(await jsonOf(response))) {
        Ok(:final value) => value,
        Err(:final error) => throw StateError('$error'),
      };
      expect(report.added.map((race) => race.id), ['imported']);
      expect(uploadRoot.listSync(), isEmpty);
    });

    test('reads a body streamed as Uint8List chunks, like dart:io', () async {
      // ARRANGE: a shelf_io a HttpRequest-et adja tovabb, ami futasidoben
      // Stream<Uint8List>; a Uint8List-torzs ezt nem idezi elo.
      final bytes = await phoneDatabaseBytes();
      final body = Stream<Uint8List>.value(
        _multipartBody([(importDatabaseField, bytes)]),
      );

      // ACT
      final response = await send(
        'POST',
        importsPath,
        body: body,
        headers: {
          ..._webClient,
          'content-type': 'multipart/form-data; boundary=$_boundary',
        },
      );

      // ASSERT
      expect(response.statusCode, 200);
      expect(uploadRoot.listSync(), isEmpty);
    });

    test('computes the stats of the imported race', () async {
      // ARRANGE
      final bytes = await phoneDatabaseBytes();

      // ACT
      await postImport([(importDatabaseField, bytes)]);

      // ASSERT
      final cached = await RaceStatsRepository(databases.web).get('imported');
      expect(cached?.window, isA<RecordingWindow>());
      expect(cached?.track.maxSpeedMps, 5);
    });

    test('rejects an upload without the database field', () async {
      final response = await postImport([(importWalField, <int>[])]);

      expect(response.statusCode, 422);
      expect(await errorOf(response), const ImportRejected(MainFileMissing()));
      expect(uploadRoot.listSync(), isEmpty);
    });

    test('rejects an unknown or repeated field with 400', () async {
      final unknown = await postImport([
        ('photo', <int>[1]),
      ]);
      final repeated = await postImport([
        (importDatabaseField, <int>[1]),
        (importDatabaseField, <int>[2]),
      ]);

      expect(unknown.statusCode, 400);
      expect(repeated.statusCode, 400);
      expect(uploadRoot.listSync(), isEmpty);
    });

    test('rejects a non-multipart body with 400', () async {
      final response = await send(
        'POST',
        importsPath,
        body: 'x',
        headers: {..._webClient, 'content-type': 'application/octet-stream'},
      );

      expect(response.statusCode, 400);
    });

    test('rejects an upload over the limit with 413', () async {
      // ARRANGE
      handler = buildHandler(importLimitBytes: 16);

      // ACT
      final response = await postImport([
        (importDatabaseField, List<int>.filled(64, 7)),
      ]);

      // ASSERT
      expect(response.statusCode, 413);
      expect(await errorOf(response), const PayloadTooLarge(16));
      expect(uploadRoot.listSync(), isEmpty);
    });

    test('rejects a non-SQLite file with 422', () async {
      final response = await postImport([
        (importDatabaseField, utf8.encode('ez nem adatbazis')),
      ]);

      expect(response.statusCode, 422);
      expect(
        await errorOf(response),
        const ImportRejected(NotSqliteDatabase()),
      );
    });

    test('requires the client header', () async {
      final response = await send('POST', importsPath, body: 'x');

      expect(response.statusCode, 403);
    });
  });
}

// Egy multipart/form-data torzs a megadott mezokkel, a megadott
// sorrendben; ismetlodo mezo is lehet benne.
Uint8List _multipartBody(List<(String, List<int>)> fields) {
  final builder = BytesBuilder();
  for (final (name, bytes) in fields) {
    builder
      ..add(
        utf8.encode(
          '--$_boundary\r\n'
          'Content-Disposition: form-data; name="$name"; filename="$name.bin"\r\n'
          'Content-Type: application/octet-stream\r\n\r\n',
        ),
      )
      ..add(bytes)
      ..add(utf8.encode('\r\n'));
  }
  builder.add(utf8.encode('--$_boundary--\r\n'));
  return builder.takeBytes();
}
