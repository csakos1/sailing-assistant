import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:foretack_web/race_edit/form/manual_race_form_values.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A kézi verseny alapadatainak szerkeszthető mezői (ADR 0048 Addendum 4
/// K16).
///
/// A [date] egyben a hivatalos rajt napja: a szerkesztő ezt adja át az
/// eredmény mezőinek, ezért ez az osztály bontja le.
class ManualRaceFormFields {
  /// Mezők az [initial] értékekkel előtöltve.
  ManualRaceFormFields(ManualRaceFormValues initial)
    : name = TextEditingController(text: initial.name),
      date = TextEditingController(text: initial.date),
      distanceKm = TextEditingController(text: initial.distanceKm),
      maxSpeedKnots = TextEditingController(text: initial.maxSpeedKnots),
      avgWindKnots = TextEditingController(text: initial.avgWindKnots),
      maxWindKnots = TextEditingController(text: initial.maxWindKnots),
      windPoint = ValueNotifier(initial.windPoint);

  /// A verseny neve.
  final TextEditingController name;

  /// A verseny napja.
  final TextEditingController date;

  /// A táv km-ben.
  final TextEditingController distanceKm;

  /// A max. sebesség csomóban.
  final TextEditingController maxSpeedKnots;

  /// Az átlagos szél csomóban.
  final TextEditingController avgWindKnots;

  /// A max. szél csomóban.
  final TextEditingController maxWindKnots;

  /// A szélirány; `null` = nincs megadva.
  final ValueNotifier<CompassPoint?> windPoint;

  /// A név-mező fókusza.
  final FocusNode nameFocus = FocusNode();

  /// A dátum-mező fókusza.
  final FocusNode dateFocus = FocusNode();

  /// A táv-mező fókusza.
  final FocusNode distanceFocus = FocusNode();

  /// A max. sebesség mezőjének fókusza.
  final FocusNode maxSpeedFocus = FocusNode();

  /// Az átlagos szél mezőjének fókusza.
  final FocusNode avgWindFocus = FocusNode();

  /// A max. szél mezőjének fókusza.
  final FocusNode maxWindFocus = FocusNode();

  /// A mezők mostani értéke.
  ManualRaceFormValues get values => (
    name: name.text,
    date: date.text,
    distanceKm: distanceKm.text,
    maxSpeedKnots: maxSpeedKnots.text,
    avgWindKnots: avgWindKnots.text,
    maxWindKnots: maxWindKnots.text,
    windPoint: windPoint.value,
  );

  /// A [problem] mezőjének fókusza, vagy `null`, ha a mező nem ezé az
  /// űrlapé (hanem az eredményé).
  FocusNode? focusNodeFor(FieldProblem problem) => switch (problem.field) {
    InputField.name => nameFocus,
    InputField.date => dateFocus,
    InputField.distanceMeters => distanceFocus,
    InputField.maxSpeedMps => maxSpeedFocus,
    InputField.avgWindMps => avgWindFocus,
    InputField.maxWindMps => maxWindFocus,
    InputField.windPoint ||
    InputField.classPlace ||
    InputField.classFleetSize ||
    InputField.overallPlace ||
    InputField.overallFleetSize ||
    InputField.monohullPlace ||
    InputField.monohullFleetSize ||
    InputField.ysNumberHundredths ||
    InputField.officialStart ||
    InputField.officialFinish ||
    InputField.prize ||
    InputField.summary => null,
  };

  /// Felszabadítja a vezérlőket.
  void dispose() {
    name.dispose();
    date.dispose();
    distanceKm.dispose();
    maxSpeedKnots.dispose();
    avgWindKnots.dispose();
    maxWindKnots.dispose();
    windPoint.dispose();
    nameFocus.dispose();
    dateFocus.dispose();
    distanceFocus.dispose();
    maxSpeedFocus.dispose();
    avgWindFocus.dispose();
    maxWindFocus.dispose();
  }
}
