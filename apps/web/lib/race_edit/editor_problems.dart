import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A szerkesztők mezőinek sorrendje a képernyőn, fentről lefelé (ADR 0048
/// Addendum 1 G4).
///
/// A mentés utáni fókusz ebben a sorrendben keresi az első hibás mezőt.
const List<InputField> editorFieldOrder = [
  InputField.name,
  InputField.date,
  InputField.classPlace,
  InputField.classFleetSize,
  InputField.overallPlace,
  InputField.overallFleetSize,
  InputField.monohullPlace,
  InputField.monohullFleetSize,
  InputField.ysNumberHundredths,
  InputField.officialStart,
  InputField.officialFinish,
  InputField.distanceMeters,
  InputField.maxSpeedMps,
  InputField.avgWindMps,
  InputField.maxWindMps,
  InputField.windPoint,
  InputField.prize,
  InputField.summary,
];

/// A [problems] közül a képernyő-sorrendben első, vagy `null`, ha nincs.
FieldProblem? firstProblemInFormOrder(List<FieldProblem> problems) {
  for (final field in editorFieldOrder) {
    final problem = problemFor(problems, field);
    if (problem != null) return problem;
  }
  return null;
}

/// A [field] mező első hibája a [problems] közül, vagy `null`.
FieldProblem? problemFor(List<FieldProblem> problems, InputField field) =>
    problems.where((problem) => problem.field == field).firstOrNull;

/// Egy sikertelen mentés üzenete a Mentés gomb fölött (K16).
enum SaveFailureMessage {
  /// A verseny már nincs az archívumban.
  raceGone,

  /// Bármi más: hálózat, szerverhiba, olvashatatlan válasz.
  saveFailed,
}

/// Mit mutasson a képernyő egy sikertelen mentés után: a szerver
/// mezőhibáit, vagy egy üzenetet.
typedef SaveFailureView = ({
  List<FieldProblem> problems,
  SaveFailureMessage? message,
});

/// A [failure] megjelenítése. A szerver validációs hibája ugyanúgy a
/// mezők alatt jelenik meg, mint a helyben talált (H5).
SaveFailureView viewOfSaveFailure(ApiFailure failure) => switch (failure) {
  ServerFailure(error: ValidationFailed(:final violations)) => (
    problems: [for (final violation in violations) RuleBroken(violation)],
    message: null,
  ),
  ServerFailure(error: RaceNotFound()) => (
    problems: const [],
    message: SaveFailureMessage.raceGone,
  ),
  _ => (problems: const [], message: SaveFailureMessage.saveFailed),
};
