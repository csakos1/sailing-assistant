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
import 'package:web_server/src/http/polar_handler.dart';
import 'package:web_server/src/http/race_detail_handler.dart';
import 'package:web_server/src/http/race_list_handler.dart';
import 'package:web_server/src/http/race_result_handler.dart';
import 'package:web_server/src/import/race_importer.dart';
import 'package:web_server/src/legacy/legacy_track_sample.dart';
import 'package:web_server/src/polar/polar_race_catalog.dart';
import 'package:web_server/src/polar/polar_table_service.dart';
import 'package:web_server/src/race/manual_race_service.dart';
import 'package:web_server/src/race/race_detail_service.dart';
import 'package:web_server/src/race/race_result_service.dart';
import 'package:web_server/src/race/race_summary_service.dart';
import 'package:web_server/src/serial_lock.dart';
import 'package:web_server/src/stats/legacy_track_stats_refresher.dart';
import 'package:web_server/src/stats/race_stats_calculator.dart';
import 'package:web_server/src/stats/race_stats_refresher.dart';
import 'package:web_server/src/stats/telemetry_stats_resolver.dart';
import 'package:web_server/src/web_db/cached_polar_stats.dart';
import 'package:web_server/src/web_db/cached_race_stats.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/polar_stats_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';

import '../polar/polar_fixtures.dart';
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
    bool hasPolar = false,
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
    final tracks = LegacyTrackRepository(web);
    final legacyRefresher = LegacyTrackStatsRefresher(
      manualRaces: manualRaces,
      results: results,
      tracks: tracks,
      stats: stats,
      calculate: RaceStatsCalculator(
        readTrackSamples: tracks.readWindow,
        readWindSamples: tracks.readWindow,
        now: () => now,
      ),
      log: logLines.add,
    );
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
          tracks: tracks,
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
          tracks: tracks,
          stats: stats,
          runInTransaction: web.transaction,
          lock: lock,
          refreshStats: legacyRefresher.refreshIfStale,
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
      polar: PolarHandler(
        hasPolar
            ? PolarTableService(
                catalog: PolarRaceCatalog(
                  races: races,
                  results: results,
                  manualRaces: manualRaces,
                  tracks: tracks,
                ),
                repository: PolarStatsRepository(web),
                fingerprint: 'fp-1',
              )
            : null,
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

  group('manual races with an old track', () {
    // ADR 0050 Addendum 2: ot minta 10 mp-enkent, 3 m/s, a hivatalos
    // ablakban (12:00-12:01 UTC).
    final start = DateTime.utc(2026, 7, 30, 12);
    final official = RaceResultInput(
      officialStart: start,
      officialFinish: start.add(const Duration(minutes: 1)),
    );

    Future<void> seedTrackedRace() async {
      await postManual(encodeManualRaceRequest(lelleRequest(result: official)));
      await LegacyTrackRepository(databases.web).replace('manual-1', [
        for (var step = 0; step < 5; step++)
          LegacyTrackSample(
            timestamp: start.add(Duration(seconds: 10 * step)),
            latDeg: 46.95 + step * 0.001,
            lonDeg: 17.9,
            sogMps: 3,
            twsMps: 5,
            twdDeg: 200,
          ),
      ]);
      // A mentes frissiti a cache-t (E2); az elso mentes meg trackkel.
      await putManual(
        'manual-1',
        encodeManualRaceRequest(lelleRequest(result: official)),
      );
    }

    test('lists the stats computed from the track', () async {
      // ARRANGE
      await seedTrackedRace();

      // ACT
      final summary = (await listRaces()).single;

      // ASSERT
      expect(
        summary.stats.window,
        OfficialWindow(
          TimeWindow(start: start, end: start.add(const Duration(minutes: 1))),
        ),
      );
      expect(summary.stats.track.maxSpeedMps, 3);
      expect(summary.stats.track.distanceMeters, closeTo(4 * 111.19, 0.1));
    });

    test('returns the old track in the detail', () async {
      // ARRANGE
      await seedTrackedRace();

      // ACT
      final response = await send('GET', racePath('manual-1'));

      // ASSERT
      final detail = unwrap(decodeRaceDetail(await jsonOf(response)));
      expect(detail.legacyTrack, hasLength(5));
      expect(detail.legacyTrack?.first.sogMps, 3);
      expect(detail.telemetry, isNull);
    });

    test('keeps the entered numbers when a save sends computed ones', () async {
      // ARRANGE
      await seedTrackedRace();
      final request = ManualRaceRequest(
        race: ManualRaceInput(
          name: 'Lelle',
          date: CalendarDate.tryParse('2026-07-30')!,
          distanceMeters: 444.8,
          maxSpeedMps: 3,
        ),
        result: official,
      );

      // ACT
      final response = await putManual(
        'manual-1',
        encodeManualRaceRequest(request),
      );

      // ASSERT
      final summary = unwrap(decodeRaceSummary(await jsonOf(response)));
      expect(summary.name, 'Lelle');
      expect(summary.stats.window, isA<OfficialWindow>());
      final stored = await ManualRaceRepository(databases.web).get('manual-1');
      expect(stored?.input.distanceMeters, 9800);
      expect(stored?.input.maxSpeedMps, isNull);
      expect(stored?.input.windPoint, CompassPoint.southEast);
    });

    test('falls back to the entered numbers without official times', () async {
      // ARRANGE
      await seedTrackedRace();

      // ACT: a hivatalos idok torlese
      final response = await putManual(
        'manual-1',
        encodeManualRaceRequest(lelleRequest()),
      );

      // ASSERT
      final summary = unwrap(decodeRaceSummary(await jsonOf(response)));
      expect(summary.stats.window, const ManualEntry());
      expect(summary.stats.track.distanceMeters, 9800);
      final detail = unwrap(
        decodeRaceDetail(await jsonOf(await send('GET', racePath('manual-1')))),
      );
      expect(detail.legacyTrack, hasLength(5));
    });

    test('DELETE removes the old track too', () async {
      // ARRANGE
      await seedTrackedRace();

      // ACT
      final response = await send(
        'DELETE',
        manualRacePath('manual-1'),
        headers: _webClient,
      );

      // ASSERT
      expect(response.statusCode, 204);
      final tracks = LegacyTrackRepository(databases.web);
      expect(await tracks.hasTrack('manual-1'), isFalse);
      expect(await RaceStatsRepository(databases.web).get('manual-1'), isNull);
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

  group('polar endpoints', () {
    test('answer 503 without a polar', () async {
      // ACT
      final responses = [
        await send('GET', polarSeasonsPath),
        await send('GET', polarSeasonPath(2026)),
        await send('GET', racePolarPath('r1')),
      ];

      // ASSERT
      for (final response in responses) {
        expect(response.statusCode, 503);
        expect(await errorOf(response), const PolarUnavailable());
      }
    });

    group('with a polar', () {
      setUp(() async {
        handler = buildHandler(hasPolar: true);
        await seedArchiveRace(databases.archive, finishedArchiveRace('r1'));
        await PolarStatsRepository(databases.web).put(
          'r1',
          CachedPolarStats(
            window: RecordingWindow(
              TimeWindow(
                start: archiveStart,
                end: archiveStart.add(const Duration(hours: 2)),
              ),
            ),
            fingerprint: 'fp-1',
            performance: uniformPerformance(seconds: 100, pct: 95),
            computedAt: now,
          ),
        );
      });

      test('gives the season table', () async {
        // ACT
        final response = await send('GET', polarSeasonPath(2026));

        // ASSERT
        expect(response.statusCode, 200);
        final table = unwrap(decodeSeasonPolarTable(await jsonOf(response)));
        expect(table.rows.single.raceId, 'r1');
        expect(table.rows.single.cacheState, PolarCacheState.fresh);
        expect(table.rows.single.rank, 1);
        expect(table.timeWeighted?.avgPct, 95);
      });

      test('gives the summary of every season', () async {
        // ACT
        final response = await send('GET', polarSeasonsPath);

        // ASSERT
        final seasons = unwrap(
          decodeSeasonPolarSummaries(await jsonOf(response)),
        );
        expect([for (final season in seasons) season.year], [2026]);
      });

      test('gives the polar block of a race', () async {
        // ACT
        final response = await send('GET', racePolarPath('r1'));

        // ASSERT
        final detail = unwrap(decodeRacePolarDetail(await jsonOf(response)));
        expect(detail.row.rank, 1);
        expect(detail.rankedCount, 1);
      });

      test('answers 404 for a race without a polar source', () async {
        // ACT
        final response = await send('GET', racePolarPath('nincs'));

        // ASSERT
        expect(response.statusCode, 404);
        expect(await errorOf(response), const RaceNotFound('nincs'));
      });

      test('answers 400 for a year that is no number', () async {
        // ACT
        final response = await send('GET', '$polarSeasonsPath/tavaly');

        // ASSERT
        expect(response.statusCode, 400);
        expect(await errorOf(response), isA<MalformedRequest>());
      });
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
