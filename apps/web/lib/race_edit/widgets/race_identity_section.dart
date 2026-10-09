import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_edit/editor_problems.dart';
import 'package:foretack_web/race_edit/field_problem_text.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:foretack_web/race_edit/form/form_text_parsers.dart';
import 'package:foretack_web/race_edit/manual_race_form_fields.dart';
import 'package:foretack_web/race_edit/widgets/boxed_text_field.dart';
import 'package:foretack_web/race_edit/widgets/editor_field_row.dart';
import 'package:foretack_web/race_edit/widgets/editor_section_label.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A kézi szerkesztő „VERSENY" szakasza: a név és a dátum, mindkettő
/// kötelező (ADR 0048 Addendum 1 G4, makett 14r).
class RaceIdentitySection extends StatelessWidget {
  /// Szakasz a [fields] mezői fölött, a [problems] hibákkal.
  const RaceIdentitySection({
    required this.fields,
    required this.problems,
    required this.autofocusName,
    super.key,
  });

  /// A kézi verseny mezői.
  final ManualRaceFormFields fields;

  /// Az űrlap összes hibája.
  final List<FieldProblem> problems;

  /// Az „Új verseny" a névvel nyílik (G5).
  final bool autofocusName;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final nameProblem = problemFor(problems, InputField.name);
    final dateProblem = problemFor(problems, InputField.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSectionLabel(text: l10n.editSectionRaceCaps),
        EditorFieldRow(
          label: l10n.editName,
          caption: l10n.editRequiredCaps,
          problemText: nameProblem == null
              ? null
              : fieldProblemText(l10n, nameProblem),
          child: BoxedTextField(
            controller: fields.name,
            focusNode: fields.nameFocus,
            label: l10n.editNameFieldCaps,
            hint: l10n.editNameHint,
            isCentered: false,
            autofocus: autofocusName,
            hasProblem: nameProblem != null,
          ),
        ),
        EditorFieldRow(
          label: l10n.editDate,
          caption: l10n.editRequiredCaps,
          problemText: dateProblem == null
              ? null
              : fieldProblemText(l10n, dateProblem),
          child: Align(
            alignment: Alignment.centerLeft,
            child: BoxedTextField(
              controller: fields.date,
              focusNode: fields.dateFocus,
              label: l10n.editDateFieldCaps,
              hint: l10n.editDateHint,
              width: WebLayout.dateFieldWidth,
              valueStyle: numeralSmallStyle.copyWith(fontSize: 17),
              hasProblem: dateProblem != null,
              normalize: _normalizedDate,
            ),
          ),
        ),
      ],
    );
  }

  static String? _normalizedDate(String text) => switch (parseFormDate(text)) {
    Ok(value: final CalendarDate date) => formatFormDate(date),
    _ => null,
  };
}
