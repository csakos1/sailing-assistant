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
}
