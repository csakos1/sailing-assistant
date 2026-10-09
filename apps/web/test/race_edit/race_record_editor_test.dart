import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/api/archive_api_client.dart';
import 'package:foretack_web/app/api_providers.dart';
import 'package:foretack_web/race_edit/race_record_editor.dart';
import 'package:foretack_web/race_log/race_log_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

void main() {
  // A szerver valaszai utvonal es metodus szerint; a lista-lekereseket
  // szamoljuk, hogy az ervenytelenites lathato legyen.
  late int listRequests;
  late http.Response Function(http.Request request) writeAnswer;

  ProviderContainer containerWithServer() {
    listRequests = 0;
    final container = ProviderContainer(
      overrides: [
        archiveApiClientProvider.overrideWithValue(
          ArchiveApiClient(
            MockClient((request) async {
              if (request.method == 'GET' && request.url.path == racesPath) {
                listRequests++;
                return http.Response(jsonEncode(encodeRaceSummaries([])), 200);
              }
              return writeAnswer(request);
            }),
            baseUri: Uri.parse('http://localhost/'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  http.Response errorAnswer(ApiError error) =>
      http.Response(jsonEncode(encodeApiError(error)), error.httpStatus);

  test('refreshes the race log after a saved result', () async {
    // ARRANGE
    final container = containerWithServer();
    writeAnswer = (_) => http.Response(
      jsonEncode(
        encodeRaceResult(
          RaceResult(
            raceId: 'r1',
            content: const RaceResultInput(overallPlace: FinishPlace(1)),
            updatedAt: DateTime.utc(2026, 10),
          ),
        ),
      ),
      200,
    );
    await container.read(raceSummariesProvider.future);

    // ACT
    final result = await container
        .read(raceRecordEditorProvider)
        .saveResult('r1', const RaceResultInput(overallPlace: FinishPlace(1)));
    await container.read(raceSummariesProvider.future);

    // ASSERT
    expect(result, isA<Ok<RaceResult, ApiFailure>>());
    expect(listRequests, 2);
  });

  test('keeps the race log when a save fails', () async {
    // ARRANGE
    final container = containerWithServer();
    writeAnswer = (_) => errorAnswer(const InternalError());
    await container.read(raceSummariesProvider.future);

    // ACT
    final result = await container
        .read(raceRecordEditorProvider)
        .saveResult('r1', const RaceResultInput());
    await container.read(raceSummariesProvider.future);

    // ASSERT
    expect(result, isA<Err<RaceResult, ApiFailure>>());
    expect(listRequests, 1);
  });

  test('treats deleting a race that is already gone as done', () async {
    // ARRANGE
    final container = containerWithServer();
    writeAnswer = (_) => errorAnswer(const RaceNotFound('m1'));

    // ACT
    final result = await container
        .read(raceRecordEditorProvider)
        .deleteManualRace('m1');

    // ASSERT
    expect(result, isA<Ok<void, ApiFailure>>());
  });

  test('reports any other delete failure', () async {
    // ARRANGE
    final container = containerWithServer();
    writeAnswer = (_) => errorAnswer(const InternalError());

    // ACT
    final result = await container
        .read(raceRecordEditorProvider)
        .deleteManualRace('m1');

    // ASSERT
    expect(result, isA<Err<void, ApiFailure>>());
  });
}
