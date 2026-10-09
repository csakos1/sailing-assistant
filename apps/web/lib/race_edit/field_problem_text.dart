import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_edit/editor_problems.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy mezőhiba mondata a mező alatt (ADR 0048 Addendum 1 G4, 13n, 14p).
///
/// A [fleetSize] a helyezés saját mezőnyének szövege: a „nagyobb a
/// mezőnynél" mondat megnevezi.
String fieldProblemText(
  WebLocalizations l10n,
  FieldProblem problem, {
  String fleetSize = '',
}) => switch (problem) {
  TextNotReadable(:final format) => switch (format) {
    TextFormat.wholeNumber => l10n.editProblemWholeNumber,
    TextFormat.decimalNumber => l10n.editProblemDecimal,
    TextFormat.ysNumber => l10n.editProblemYs,
    TextFormat.date => l10n.editProblemDate,
    TextFormat.time => l10n.editProblemTime,
  },
  RuleBroken(:final violation) => switch (violation) {
    ValueNotPositive(:final field) => _notPositiveText(l10n, field),
    PlaceExceedsFleetSize() => l10n.editProblemPlaceExceedsFleet(fleetSize),
    FinishNotAfterStart() => l10n.editProblemFinishNotAfterStart,
    ValueNegative() => l10n.editProblemNegative,
    ValueEmpty() => l10n.editProblemRequired,
  },
};

/// A sikertelen mentés mondata a Mentés gomb fölött (K16).
String saveFailureText(WebLocalizations l10n, SaveFailureMessage message) =>
    switch (message) {
      SaveFailureMessage.raceGone => l10n.editRaceGone,
      SaveFailureMessage.saveFailed => l10n.editSaveFailed,
    };

String _notPositiveText(WebLocalizations l10n, InputField field) {
  if (_placeFields.contains(field)) return l10n.editProblemPlaceAtLeastOne;
  if (_fleetSizeFields.contains(field)) {
    return l10n.editProblemFleetAtLeastOne;
  }
  if (field == InputField.ysNumberHundredths) {
    return l10n.editProblemYsAtLeastOne;
  }
  return l10n.editProblemAtLeastOne;
}

const Set<InputField> _placeFields = {
  InputField.classPlace,
  InputField.overallPlace,
  InputField.monohullPlace,
};

const Set<InputField> _fleetSizeFields = {
  InputField.classFleetSize,
  InputField.overallFleetSize,
  InputField.monohullFleetSize,
};
