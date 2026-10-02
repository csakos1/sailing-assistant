import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_detail/detail_formatters.dart';
import 'package:foretack_web/race_edit/editor_problems.dart';
import 'package:foretack_web/race_edit/field_problem_text.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:foretack_web/race_edit/form/form_text_parsers.dart';
import 'package:foretack_web/race_edit/result_form_fields.dart';
import 'package:foretack_web/race_edit/widgets/boxed_text_field.dart';
import 'package:foretack_web/race_edit/widgets/editor_field_row.dart';
import 'package:foretack_web/race_edit/widgets/editor_section_label.dart';
import 'package:foretack_web/race_edit/widgets/placing_pair_row.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Az „EREDMÉNY" szakasz: a három helyezés-pár és a YS-szám (ADR 0048
/// Addendum 1 G4).
class ResultPlacingsSection extends StatelessWidget {
  /// Szakasz a [fields] mezői fölött, a [problems] hibákkal.
  const ResultPlacingsSection({
    required this.fields,
    required this.problems,
    super.key,
  });

  /// Az eredmény-űrlap mezői.
  final ResultFormFields fields;

  /// Az űrlap összes hibája.
  final List<FieldProblem> problems;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final ysProblem = problemFor(problems, InputField.ysNumberHundredths);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSectionLabel(text: l10n.editSectionResultCaps),
        PlacingPairRow(
          label: l10n.editClassPlace,
          fields: fields.classPlacing,
          placeField: InputField.classPlace,
          fleetSizeField: InputField.classFleetSize,
          problems: problems,
        ),
        PlacingPairRow(
          label: l10n.editOverallPlace,
          fields: fields.overallPlacing,
          placeField: InputField.overallPlace,
          fleetSizeField: InputField.overallFleetSize,
          problems: problems,
        ),
        PlacingPairRow(
          label: l10n.editMonohullPlace,
          fields: fields.monohullPlacing,
          placeField: InputField.monohullPlace,
          fleetSizeField: InputField.monohullFleetSize,
          problems: problems,
        ),
        EditorFieldRow(
          label: l10n.editYs,
          problemText: ysProblem == null
              ? null
              : fieldProblemText(l10n, ysProblem),
          child: Row(
            children: [
              BoxedTextField(
                controller: fields.ysNumber,
                focusNode: fields.ysNumberFocus,
                label: l10n.editYsFieldCaps,
                width: WebLayout.timeFieldWidth,
                valueStyle: numeralSmallStyle.copyWith(fontSize: 17),
                hasProblem: ysProblem != null,
                normalize: _normalizedYs,
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  l10n.editYsHint,
                  style: supportTextStyle.copyWith(
                    color: Theme.of(context).extension<TextTones>()!.low,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String? _normalizedYs(String text) => switch (parseYsNumber(text)) {
    Ok(value: final int hundredths) => formatYsNumber(hundredths),
    _ => null,
  };
}
