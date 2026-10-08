import 'package:flutter/foundation.dart';
import 'package:phone/features/web_access/application/scan_problem.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/pending_join.dart';
import 'package:shared/shared.dart';

/// Egy csatlakozási kísérlet kimenete a képernyőknek (ADR 0051 Addendum 9
/// X2).
@immutable
sealed class JoinSubmission {
  const JoinSubmission();
}

/// A kérelem elment; a 18e-2 jön.
final class JoinSubmitted extends JoinSubmission {
  /// A beküldött [pending] kérelem.
  const JoinSubmitted(this.pending);

  /// A függő kérelem.
  final PendingJoin pending;
}

/// A felhasználó elvetette az ujjlenyomat-ablakot: a 18e marad (X2).
final class JoinCanceled extends JoinSubmission {
  const JoinCanceled();
}

/// A kérelem nem ment el; a [problem] panel jön, a név megmarad.
final class JoinFailed extends JoinSubmission {
  /// Sikertelen küldés a [problem] panellel.
  const JoinFailed(this.problem);

  /// A beolvasó hibapanelje.
  final ScanProblem problem;
}

/// A csatlakozás folyamatának [result]-ja → [JoinSubmission].
///
/// A csatlakozó telefonnak még nincs fiókja, ezért a visszavont-panel
/// (amit itt egy elveszett kulcs adhatna) a legénységé.
JoinSubmission joinSubmissionOf(Result<PendingJoin, WebAccessError> result) =>
    switch (result) {
      Ok(:final value) => JoinSubmitted(value),
      Err(:final error) => switch (scanProblemOf(
        error,
        isOwner: false,
        kind: ScanKind.join,
      )) {
        null => const JoinCanceled(),
        final ScanProblem problem => JoinFailed(problem),
      },
    };
