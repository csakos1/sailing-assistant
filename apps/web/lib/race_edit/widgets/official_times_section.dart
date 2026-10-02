import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_detail/detail_formatters.dart';
import 'package:foretack_web/race_edit/editor_problems.dart';
import 'package:foretack_web/race_edit/field_problem_text.dart';
import 'package:foretack_web/race_edit/form/clock_time.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:foretack_web/race_edit/form/form_text_parsers.dart';
import 'package:foretack_web/race_edit/form/read_result_form.dart';
import 'package:foretack_web/race_edit/result_form_fields.dart';
import 'package:foretack_web/race_edit/widgets/boxed_text_field.dart';
import 'package:foretack_web/race_edit/widgets/choice_segment.dart';
import 'package:foretack_web/race_edit/widgets/computed_value_row.dart';
import 'package:foretack_web/race_edit/widgets/editor_field_row.dart';
import 'package:foretack_web/race_edit/widgets/editor_section_label.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A „HIVATALOS IDŐ" szakasz: rajt, befutás és a számolt menetidő (ADR
/// 0048 Addendum 1 G4, Addendum 4 K11).
///
/// A befutás napja a rajt napjához képest egy `[AZNAP | +1 NAP | +2 NAP]`
/// szegmens. A rajt napjának mezője csak telemetriásnál látszik
/// ([showsStartDate]); kézinél a verseny dátuma a rajt napja.
class OfficialTimesSection extends StatelessWidget {
  /// Szakasz a [fields] mezői fölött, a [problems] hibákkal.
  const OfficialTimesSection({
    required this.fields,
    required this.problems,
    required this.showsStartDate,
    super.key,
  });

  /// Az eredmény-űrlap mezői.
  final ResultFormFields fields;

  /// Az űrlap összes hibája.
  final List<FieldProblem> problems;

  /// Látszik-e a rajt napjának mezője.
  final bool showsStartDate;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final startProblem = problemFor(problems, InputField.officialStart);
    final finishProblem = problemFor(problems, InputField.officialFinish);
    final isStartDateProblem =
        startProblem is TextNotReadable &&
        startProblem.format == TextFormat.date;
    final timeStyle = numeralSmallStyle.copyWith(fontSize: 17);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSectionLabel(text: l10n.editSectionTimesCaps),
        EditorFieldRow(
          label: l10n.editOfficialStart,
          problemText: startProblem == null
              ? null
              : fieldProblemText(l10n, startProblem),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (showsStartDate)
                BoxedTextField(
                  controller: fields.startDate,
                  focusNode: fields.startDateFocus,
                  label: l10n.editDateFieldCaps,
                  hint: l10n.editDateHint,
                  width: WebLayout.dateFieldWidth,
                  valueStyle: timeStyle,
                  hasProblem: isStartDateProblem,
                  normalize: _normalizedDate,
                ),
              BoxedTextField(
                controller: fields.startTime,
                focusNode: fields.startTimeFocus,
                label: l10n.editTimeFieldCaps,
                hint: l10n.editTimeHint,
                width: WebLayout.timeFieldWidth,
                valueStyle: timeStyle,
                hasProblem: startProblem != null && !isStartDateProblem,
                normalize: _normalizedTime,
              ),
            ],
          ),
        ),
        EditorFieldRow(
          label: l10n.editOfficialFinish,
          problemText: finishProblem == null
              ? null
              : fieldProblemText(l10n, finishProblem),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              BoxedTextField(
                controller: fields.finishTime,
                focusNode: fields.finishTimeFocus,
                label: l10n.editTimeFieldCaps,
                hint: l10n.editTimeHint,
                width: WebLayout.timeFieldWidth,
                valueStyle: timeStyle,
                hasProblem: finishProblem != null,
                normalize: _normalizedTime,
              ),
              ValueListenableBuilder<int>(
                valueListenable: fields.finishDayOffset,
                builder: (context, offset, _) => ChoiceSegment<int>(
                  options: [
                    (value: 0, label: l10n.editSameDayCaps),
                    (value: 1, label: l10n.editNextDayCaps),
                    (value: 2, label: l10n.editSecondDayCaps),
                  ],
                  selected: offset,
                  onSelected: (selected) =>
                      fields.finishDayOffset.value = selected,
                ),
              ),
            ],
          ),
        ),
        ListenableBuilder(
          listenable: fields.changes,
          builder: (context, _) {
            final elapsed = formOfficialElapsed(fields.values);
            return ComputedValueRow(
              label: l10n.editElapsed,
              value: elapsed == null ? null : formatElapsed(elapsed),
              explanation: l10n.editElapsedSourceCaps,
            );
          },
        ),
      ],
    );
  }

  static String? _normalizedDate(String text) => switch (parseFormDate(text)) {
    Ok(value: final CalendarDate date) => formatFormDate(date),
    _ => null,
  };

  static String? _normalizedTime(String text) => switch (parseClockTime(text)) {
    Ok(value: final ClockTime time) => formatClockTime(time),
    _ => null,
  };
}
