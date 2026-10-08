import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/application/join_submission.dart';
import 'package:phone/features/web_access/application/scan_problem.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/pending_join.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

import '../web_access_fakes.dart';

void main() {
  JoinSubmission failureOf(WebAccessError error) =>
      joinSubmissionOf(Err<PendingJoin, WebAccessError>(error));

  test('a sent request opens the pending screen', () {
    // Act
    final submission = joinSubmissionOf(
      Ok<PendingJoin, WebAccessError>(testPendingJoin()),
    );

    // Assert
    expect((submission as JoinSubmitted).pending, testPendingJoin());
  });

  test('a dismissed fingerprint stays on the form', () {
    // Act
    final submission = failureOf(
      const KeyOperationFailed(KeyOperationFailure.canceled),
    );

    // Assert
    expect(submission, isA<JoinCanceled>());
  });

  test('an expired login request says the name was kept', () {
    // Act
    final submission = failureOf(
      const ApiCallFailed(WebServerFailure(RequestExpired())),
    );

    // Assert
    final problem = (submission as JoinFailed).problem;
    expect((problem as ExpiredCode).kind, ScanKind.join);
  });

  test('a lost key offers a new join, as for the crew', () {
    // Act
    final submission = failureOf(
      const KeyOperationFailed(KeyOperationFailure.keyMissing),
    );

    // Assert
    final problem = (submission as JoinFailed).problem;
    expect((problem as DeviceRevokedProblem).isOwner, isFalse);
  });
}
