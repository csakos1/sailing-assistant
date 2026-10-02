import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/api/archive_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

import '../support/sample_summaries.dart';

void main() {
  final baseUri = Uri.parse('http://localhost:8080/');

  ArchiveApiClient clientAnswering(
    Future<http.Response> Function(http.Request request) handler,
  ) => ArchiveApiClient(MockClient(handler), baseUri: baseUri);

  http.Response jsonResponse(Object? body, {int status = 200}) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  ApiFailure failureOf<T>(Result<T, ApiFailure> result) => switch (result) {
    Ok() => throw StateError('Err-t vartunk'),
    Err(:final error) => error,
  };

  group('ArchiveApiClient.fetchRaceSummaries', () {
    test('requests the race list relative to the base address', () async {
      // ARRANGE
      Uri? requested;
      final client = clientAnswering((request) async {
        requested = request.url;
        return jsonResponse(encodeRaceSummaries(const []));
      });

      // ACT
      await client.fetchRaceSummaries();

      // ASSERT
      expect(requested, Uri.parse('http://localhost:8080/api/races'));
    });

    test('decodes the summaries, accented names included', () async {
      // ARRANGE
      final summaries = [
        telemetrySummary('r1', start: DateTime(2026, 7, 26, 11)),
        manualSummary('m1', date: '2025-08-23'),
      ];
      final client = clientAnswering(
        (request) async => jsonResponse(encodeRaceSummaries(summaries)),
      );

      // ACT
      final result = await client.fetchRaceSummaries();

      // ASSERT: az Ok == a listat identitas szerint hasonlitana
      final decoded = switch (result) {
        Ok(:final value) => value,
        Err(:final error) => throw StateError('Ok-t vartunk: $error'),
      };
      expect(decoded, summaries);
    });

    test('maps an error envelope to a server failure', () async {
      final client = clientAnswering(
        (request) async =>
            jsonResponse(encodeApiError(const InternalError()), status: 500),
      );

      final failure = failureOf(await client.fetchRaceSummaries());

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).error, const InternalError());
    });

    test('maps a body that is not JSON to an unreadable response', () async {
      final client = clientAnswering(
        (request) async => http.Response('<html>502</html>', 502),
      );

      final failure = failureOf(await client.fetchRaceSummaries());

      expect(failure, isA<UnreadableResponse>());
      expect((failure as UnreadableResponse).statusCode, 502);
    });

    test('maps a JSON of the wrong shape to an unreadable response', () async {
      final client = clientAnswering(
        (request) async => jsonResponse({'races': 'nincs'}),
      );

      final failure = failureOf(await client.fetchRaceSummaries());

      expect(
        (failure as UnreadableResponse).decodeError?.path,
        r'$.races',
      );
    });

    test('maps a client exception to a network failure', () async {
      final client = clientAnswering(
        (request) async => throw http.ClientException('offline'),
      );

      final failure = failureOf(await client.fetchRaceSummaries());

      expect(failure, isA<NetworkFailure>());
    });
  });

  group('ArchiveApiClient writes', () {
    test('puts a result as JSON with the client header', () async {
      // ARRANGE
      http.Request? sent;
      final client = clientAnswering((request) async {
        sent = request;
        return jsonResponse(
          encodeRaceResult(
            RaceResult(
              raceId: 'r1',
              content: const RaceResultInput(overallPlace: FinishPlace(3)),
              updatedAt: DateTime.utc(2026, 10),
            ),
          ),
        );
      });

      // ACT
      final result = await client.saveRaceResult(
        'r1',
        const RaceResultInput(overallPlace: FinishPlace(3)),
      );

      // ASSERT
      expect(result, isA<Ok<RaceResult, ApiFailure>>());
      expect(sent?.method, 'PUT');
      expect(sent?.url.path, raceResultPath('r1'));
      expect(sent?.headers[clientHeaderName], clientHeaderWebValue);
      expect(sent?.headers['content-type'], startsWith('application/json'));
      expect(
        jsonDecode(sent?.body ?? ''),
        encodeRaceResultInput(
          const RaceResultInput(overallPlace: FinishPlace(3)),
        ),
      );
    });

    test('posts a new manual race and reads its summary', () async {
      // ARRANGE
      http.Request? sent;
      final created = manualSummary('m9', date: '2025-10-19');
      final client = clientAnswering((request) async {
        sent = request;
        return jsonResponse(encodeRaceSummary(created), status: 201);
      });
      final request = ManualRaceRequest(
        race: ManualRaceInput(
          name: 'Siofoki Evadzaro',
          // A `!` biztonsagos: letezo nap.
          date: CalendarDate.tryParse('2025-10-19')!,
        ),
      );

      // ACT
      final result = await client.createManualRace(request);

      // ASSERT
      expect(sent?.method, 'POST');
      expect(sent?.url.path, manualRacesPath);
      expect(sent?.headers[clientHeaderName], clientHeaderWebValue);
      expect(switch (result) {
        Ok(:final value) => value,
        Err(:final error) => throw StateError('Ok-t vartunk: $error'),
      }, created);
    });

    test('puts a manual race to its own path', () async {
      // ARRANGE
      http.Request? sent;
      final client = clientAnswering((request) async {
        sent = request;
        return jsonResponse(
          encodeRaceSummary(manualSummary('m9', date: '2025-10-19')),
        );
      });

      // ACT
      await client.updateManualRace(
        'm9',
        ManualRaceRequest(
          race: ManualRaceInput(
            name: 'Uj nev',
            date: CalendarDate.tryParse('2025-10-19')!,
          ),
        ),
      );

      // ASSERT
      expect(sent?.method, 'PUT');
      expect(sent?.url.path, manualRacePath('m9'));
    });

    test('deletes a manual race and accepts the empty 204', () async {
      // ARRANGE
      http.Request? sent;
      final client = clientAnswering((request) async {
        sent = request;
        return http.Response('', 204);
      });

      // ACT
      final result = await client.deleteManualRace('m9');

      // ASSERT
      expect(result, isA<Ok<void, ApiFailure>>());
      expect(sent?.method, 'DELETE');
      expect(sent?.url.path, manualRacePath('m9'));
      expect(sent?.headers[clientHeaderName], clientHeaderWebValue);
    });

    test('maps a validation error of a write to a server failure', () async {
      final client = clientAnswering(
        (request) async => jsonResponse(
          encodeApiError(
            const ValidationFailed([
              PlaceExceedsFleetSize(InputField.overallPlace),
            ]),
          ),
          status: 422,
        ),
      );

      final failure = failureOf(
        await client.saveRaceResult('r1', const RaceResultInput()),
      );

      expect(
        (failure as ServerFailure).error,
        const ValidationFailed([
          PlaceExceedsFleetSize(InputField.overallPlace),
        ]),
      );
    });

    test('maps a missing race on delete to a server failure', () async {
      final client = clientAnswering(
        (request) async => jsonResponse(
          encodeApiError(const RaceNotFound('m9')),
          status: 404,
        ),
      );

      final failure = failureOf(await client.deleteManualRace('m9'));

      expect((failure as ServerFailure).error, const RaceNotFound('m9'));
    });
  });
}
