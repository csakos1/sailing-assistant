import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:data/data.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:web_server/src/annotation/annotation_repository.dart';
import 'package:web_server/src/http/annotation_handler.dart';
import 'package:web_server/src/http/archive_api.dart';
import 'package:web_server/src/http/import_handler.dart';
import 'package:web_server/src/http/import_upload_receiver.dart';
import 'package:web_server/src/http/race_detail_handler.dart';
import 'package:web_server/src/http/race_list_handler.dart';
import 'package:web_server/src/import/race_importer.dart';
import 'package:web_server/src/race/race_detail_service.dart';
import 'package:web_server/src/race/race_list_service.dart';

import '../support/archive_fixture.dart';

// Handler-szintu tesztek: valodi shelf Request-ek a teljes pipeline-on at
// (naplo, kivetelfogo, fejlec-or, router), socket nelkul, valodi
// ideiglenes DB-kkel.

const _boundary = 'foretack-test-boundary';
const Map<String, String> _webClient = {clientHeaderName: clientHeaderWebValue};

void main() {
  late ArchiveDatabases databases;
  late Directory uploadRoot;
  late Handler handler;
  late List<String> logLines;
  final now = DateTime.utc(2026, 10, 1, 8, 30);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  Handler buildHandler({
    int importLimitBytes = 8 * 1024 * 1024,
    int annotationLimitBytes = 1024,
  }) {
    final archive = databases.archive;
    final races = RaceRepositoryImpl(archive);
    final annotations = AnnotationRepository(databases.web);
    return buildArchiveApiHandler(
      raceList: RaceListHandler(
        RaceListService(
          races: races,
          readTrackStats: RaceTrackStatsRepositoryImpl(archive).read,
          readTrackSamples: TrackSampleReaderImpl(archive).call,
          annotations: annotations,
          log: logLines.add,
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
        bodyLimitBytes: annotationLimitBytes,
        now: () => now,
      ),
      imports: ImportHandler(
        importer: RaceImporter(archive: archive, tempRoot: uploadRoot),
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

  Future<ApiError> errorOf(Response response) async => switch (decodeApiError(
    await jsonOf(response),
  )) {
    Ok(:final value) => value,
    Err(:final error) => throw StateError('Hibaboritekot vartunk: $error'),
  };

  Future<Response> putAnnotation(String raceId, Object? json) => send(
    'PUT',
    raceAnnotationPath(raceId),
    body: jsonEncode(json),
    headers: _webClient,
  );

  group('GET $racesPath', () {
    test('lists finished races newest first with annotations', () async {
      // ARRANGE
      await seedArchiveRace(databases.archive, finishedArchiveRace('old'));
      await seedArchiveRace(
        databases.archive,
        finishedArchiveRace('new', offset: const Duration(days: 7)),
      );
      await putAnnotation('old', {'overallPlace': 3, 'overallFleetSize': 24});

      // ACT
      final response = await send('GET', racesPath);

      // ASSERT
      expect(response.statusCode, 200);
      final items = switch (decodeRaceList(await jsonOf(response))) {
        Ok(:final value) => value,
        Err(:final error) => throw StateError('$error'),
      };
      expect(items.map((item) => item.race.id), ['new', 'old']);
      expect(items.first.annotation, isNull);
      expect(items.last.annotation?.content.overallPlace, 3);
      expect(items.first.trackStats.distanceMeters, 1234);
    });

    test(
      'computes missing track stats in memory without writing them',
      () async {
        // ARRANGE
        await seedArchiveRace(
          databases.archive,
          finishedArchiveRace('r1'),
          withStats: false,
        );

        // ACT
        final response = await send('GET', racesPath);

        // ASSERT
        expect(response.statusCode, 200);
        final items = switch (decodeRaceList(await jsonOf(response))) {
          Ok(:final value) => value,
          Err(:final error) => throw StateError('$error'),
        };
        expect(items.single.trackStats.maxSpeedMps, 5);
        expect(
          await RaceTrackStatsRepositoryImpl(databases.archive).read('r1'),
          isNull,
        );
        expect(
          logLines.where((line) => line.contains('race_track_stats')),
          hasLength(1),
        );
      },
    );
  });

  group('GET $racesPath/{id}', () {
    test(
      'returns the detail with track points of positioned samples',
      () async {
        // ARRANGE
        await seedArchiveRace(databases.archive, finishedArchiveRace('r1'));

        // ACT
        final response = await send('GET', racePath('r1'));

        // ASSERT
        expect(response.statusCode, 200);
        final detail = switch (decodeLegacyRaceDetail(await jsonOf(response))) {
          Ok(:final value) => value,
          Err(:final error) => throw StateError('$error'),
        };
        expect(detail.race.id, 'r1');
        // Harom pozicios minta, a pozicio nelkuli kimarad.
        expect(detail.trackPoints, hasLength(3));
        expect(detail.trackPoints.last.sogMps, 5);
        expect(detail.trackStats.maxSpeedMps, 5);
        expect(detail.annotation, isNull);
      },
    );

    test('answers 404 for an unknown race', () async {
      final response = await send('GET', racePath('missing'));

      expect(response.statusCode, 404);
      expect(await errorOf(response), const RaceNotFound('missing'));
    });
  });

  group('PUT annotation', () {
    setUp(() => seedArchiveRace(databases.archive, finishedArchiveRace('r1')));

    test('saves a normalized annotation and returns it', () async {
      // ACT
      final response = await putAnnotation('r1', {
        'overallPlace': 3,
        'overallFleetSize': 24,
        'summary': '  Jo nap.  ',
      });

      // ASSERT
      expect(response.statusCode, 200);
      final saved = switch (decodeRaceAnnotation(await jsonOf(response))) {
        Ok(:final value) => value,
        Err(:final error) => throw StateError('$error'),
      };
      expect(saved.content.summary, 'Jo nap.');
      expect(saved.updatedAt, DateTime.utc(2026, 10, 1, 8, 30));
      expect(await AnnotationRepository(databases.web).get('r1'), saved);
    });

    test('deletes the annotation when every field is empty', () async {
      // ARRANGE
      await putAnnotation('r1', {'overallPlace': 3});

      // ACT
      final response = await putAnnotation('r1', {'summary': '   '});

      // ASSERT
      expect(response.statusCode, 200);
      expect(await AnnotationRepository(databases.web).get('r1'), isNull);
    });

    test('rejects every violation at once with 422', () async {
      final response = await putAnnotation('r1', {
        'overallPlace': 5,
        'overallFleetSize': 3,
        'classPlace': 0,
      });

      expect(response.statusCode, 422);
      expect(
        await errorOf(response),
        const ValidationFailed([
          PlaceExceedsFleetSize(AnnotationField.overallPlace),
          ValueNotPositive(AnnotationField.classPlace),
        ]),
      );
    });

    test('rejects a body that is not JSON with 400', () async {
      final response = await send(
        'PUT',
        raceAnnotationPath('r1'),
        body: '{nem json',
        headers: _webClient,
      );

      expect(response.statusCode, 400);
      expect(await errorOf(response), isA<MalformedRequest>());
    });

    test('rejects a wrongly typed field with 400', () async {
      final response = await putAnnotation('r1', {'overallPlace': 'harmadik'});

      expect(response.statusCode, 400);
      expect(await errorOf(response), isA<MalformedRequest>());
    });

    test('answers 404 for an unknown race', () async {
      final response = await putAnnotation('missing', {'overallPlace': 1});

      expect(response.statusCode, 404);
    });

    test('rejects an oversized body with 413', () async {
      final response = await putAnnotation('r1', {'summary': 'x' * 2048});

      expect(response.statusCode, 413);
      expect(await errorOf(response), const PayloadTooLarge(1024));
    });

    test('requires the client header', () async {
      final response = await send(
        'PUT',
        raceAnnotationPath('r1'),
        body: jsonEncode({'overallPlace': 1}),
      );

      expect(response.statusCode, 403);
      expect(await errorOf(response), const MissingClientHeader());
      expect(await AnnotationRepository(databases.web).get('r1'), isNull);
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
