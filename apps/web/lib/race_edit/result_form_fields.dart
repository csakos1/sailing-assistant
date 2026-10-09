import 'package:flutter/widgets.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:foretack_web/race_edit/form/result_form_values.dart';
import 'package:foretack_web/race_edit/placing_fields.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Az eredmény-űrlap szerkeszthető mezői (ADR 0048 Addendum 4 K16).
///
/// Widget-lokális állapot: a szerkesztő képernyő hozza létre és bontja
/// le. A [values] a pure olvasó és a mentetlenség-vizsgálat bemenete.
///
/// Kézi versenynél a rajt napja a verseny dátum-mezője: ezt a hívó a
/// `sharedStartDate`-ben adja át, és ő is bontja le.
class ResultFormFields {
  /// Mezők az [initial] értékekkel; a [sharedStartDate] a rajt napjának
  /// külső mezője, ha van.
  ResultFormFields(
    ResultFormValues initial, {
    TextEditingController? sharedStartDate,
  }) : classPlacing = PlacingFields(initial.classPlacing),
       overallPlacing = PlacingFields(initial.overallPlacing),
       monohullPlacing = PlacingFields(initial.monohullPlacing),
       ysNumber = TextEditingController(text: initial.ysNumber),
       startDate =
           sharedStartDate ?? TextEditingController(text: initial.startDate),
       _ownsStartDate = sharedStartDate == null,
       startTime = TextEditingController(text: initial.startTime),
       finishTime = TextEditingController(text: initial.finishTime),
       finishDayOffset = ValueNotifier(initial.finishDayOffset),
       prize = TextEditingController(text: initial.prize),
       summary = TextEditingController(text: initial.summary);

  /// Az osztályhelyezés párja.
  final PlacingFields classPlacing;

  /// Az abszolút helyezés párja.
  final PlacingFields overallPlacing;

  /// Az egytestű helyezés párja.
  final PlacingFields monohullPlacing;

  /// A YS-szám szövege.
  final TextEditingController ysNumber;

  /// A hivatalos rajt napja.
  final TextEditingController startDate;

  final bool _ownsStartDate;

  /// A hivatalos rajt ideje.
  final TextEditingController startTime;

  /// A hivatalos befutás ideje.
  final TextEditingController finishTime;

  /// A befutás napja a rajt napjához képest (0–2).
  final ValueNotifier<int> finishDayOffset;

  /// A díj szövege.
  final TextEditingController prize;

  /// Az összefoglaló szövege.
  final TextEditingController summary;

  /// A YS-mező fókusza.
  final FocusNode ysNumberFocus = FocusNode();

  /// A rajt napjának fókusza (csak telemetriásnál látszik).
  final FocusNode startDateFocus = FocusNode();

  /// A rajt idejének fókusza.
  final FocusNode startTimeFocus = FocusNode();

  /// A befutás idejének fókusza.
  final FocusNode finishTimeFocus = FocusNode();

  /// A mezők mostani értéke.
  ResultFormValues get values => (
    classPlacing: classPlacing.values,
    overallPlacing: overallPlacing.values,
    monohullPlacing: monohullPlacing.values,
    ysNumber: ysNumber.text,
    startDate: startDate.text,
    startTime: startTime.text,
    finishTime: finishTime.text,
    finishDayOffset: finishDayOffset.value,
    prize: prize.text,
    summary: summary.text,
  );

  /// Minden változás egy jelzésben (a számolt sorok frissítéséhez).
  late final Listenable changes = Listenable.merge([
    classPlacing.changes,
    overallPlacing.changes,
    monohullPlacing.changes,
    ysNumber,
    startDate,
    startTime,
    finishTime,
    finishDayOffset,
  ]);

  /// A [problem] mezőjének fókusza, vagy `null`, ha a mező nem ezé az
  /// űrlapé. A rajt napjának olvasási hibája a dátum-mezőé, ha az látszik
  /// ([showsStartDate]).
  FocusNode? focusNodeFor(
    FieldProblem problem, {
    required bool showsStartDate,
  }) => switch (problem.field) {
    InputField.classPlace => classPlacing.placeFocus,
    InputField.classFleetSize => classPlacing.fleetSizeFocus,
    InputField.overallPlace => overallPlacing.placeFocus,
    InputField.overallFleetSize => overallPlacing.fleetSizeFocus,
    InputField.monohullPlace => monohullPlacing.placeFocus,
    InputField.monohullFleetSize => monohullPlacing.fleetSizeFocus,
    InputField.ysNumberHundredths => ysNumberFocus,
    InputField.officialStart =>
      showsStartDate &&
              problem is TextNotReadable &&
              problem.format == TextFormat.date
          ? startDateFocus
          : startTimeFocus,
    InputField.officialFinish => finishTimeFocus,
    InputField.prize ||
    InputField.summary ||
    InputField.name ||
    InputField.date ||
    InputField.distanceMeters ||
    InputField.maxSpeedMps ||
    InputField.avgWindMps ||
    InputField.maxWindMps ||
    InputField.windPoint => null,
  };

  /// Felszabadítja a vezérlőket; a külső rajt-nap mezőt nem.
  void dispose() {
    classPlacing.dispose();
    overallPlacing.dispose();
    monohullPlacing.dispose();
    ysNumber.dispose();
    if (_ownsStartDate) startDate.dispose();
    startTime.dispose();
    finishTime.dispose();
    finishDayOffset.dispose();
    prize.dispose();
    summary.dispose();
    ysNumberFocus.dispose();
    startDateFocus.dispose();
    startTimeFocus.dispose();
    finishTimeFocus.dispose();
  }
}
