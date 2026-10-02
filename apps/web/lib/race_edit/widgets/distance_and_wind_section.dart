import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_edit/editor_problems.dart';
import 'package:foretack_web/race_edit/field_problem_text.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:foretack_web/race_edit/form/form_text_parsers.dart';
import 'package:foretack_web/race_edit/form/read_manual_race_form.dart';
import 'package:foretack_web/race_edit/form/read_result_form.dart';
import 'package:foretack_web/race_edit/manual_race_form_fields.dart';
import 'package:foretack_web/race_edit/result_form_fields.dart';
import 'package:foretack_web/race_edit/widgets/boxed_text_field.dart';
import 'package:foretack_web/race_edit/widgets/computed_value_row.dart';
import 'package:foretack_web/race_edit/widgets/editor_field_row.dart';
import 'package:foretack_web/race_edit/widgets/editor_section_label.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A kézi szerkesztő „TÁV ÉS SZÉL" szakasza (ADR 0048 Addendum 1 G4,
/// Addendum 4 K11–K12): táv és max. sebesség, a számolt átlagsebesség,
/// a szél és a szélirány lenyíló listája.
class DistanceAndWindSection extends StatelessWidget {
  /// Szakasz a [fields] mezői fölött; az átlagsebességhez a [resultFields]
  /// menetideje kell.
  const DistanceAndWindSection({
    required this.fields,
    required this.resultFields,
    required this.problems,
    super.key,
  });

  /// A kézi verseny mezői.
  final ManualRaceFormFields fields;

  /// Az eredmény mezői (a hivatalos menetidőhöz).
  final ResultFormFields resultFields;

  /// Az űrlap összes hibája.
  final List<FieldProblem> problems;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSectionLabel(text: l10n.editSectionDistanceWindCaps),
        _QuantityPairRow(
          label: l10n.editDistanceSpeed,
          problems: problems,
          first: (
            controller: fields.distanceKm,
            focusNode: fields.distanceFocus,
            label: l10n.editDistanceFieldCaps,
            field: InputField.distanceMeters,
          ),
          second: (
            controller: fields.maxSpeedKnots,
            focusNode: fields.maxSpeedFocus,
            label: l10n.editMaxKnotsFieldCaps,
            field: InputField.maxSpeedMps,
          ),
        ),
        ListenableBuilder(
          listenable: Listenable.merge([
            fields.distanceKm,
            resultFields.changes,
          ]),
          builder: (context, _) {
            final speed = formAverageSpeedMps(
              fields.distanceKm.text,
              formOfficialElapsed(resultFields.values),
            );
            return ComputedValueRow(
              label: l10n.editAvgSpeed,
              value: speed == null
                  ? null
                  : l10n.editKnotsValue(measureKnots(speed).value),
              explanation: l10n.editAvgSpeedSourceCaps,
            );
          },
        ),
        _QuantityPairRow(
          label: l10n.editWind,
          problems: problems,
          first: (
            controller: fields.avgWindKnots,
            focusNode: fields.avgWindFocus,
            label: l10n.editAvgKnotsFieldCaps,
            field: InputField.avgWindMps,
          ),
          second: (
            controller: fields.maxWindKnots,
            focusNode: fields.maxWindFocus,
            label: l10n.editMaxKnotsFieldCaps,
            field: InputField.maxWindMps,
          ),
        ),
        EditorFieldRow(
          label: l10n.editWindDirection,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: WebLayout.windPointFieldWidth,
              child: _WindPointDropdown(windPoint: fields.windPoint),
            ),
          ),
        ),
      ],
    );
  }
}

/// Egy mennyiség-mező leírása a pár-sorban.
typedef _QuantityField = ({
  TextEditingController controller,
  FocusNode focusNode,
  String label,
  InputField field,
});

/// Két tizedes mennyiség egy sorban, közös hibasorral.
class _QuantityPairRow extends StatelessWidget {
  const _QuantityPairRow({
    required this.label,
    required this.problems,
    required this.first,
    required this.second,
  });

  final String label;
  final List<FieldProblem> problems;
  final _QuantityField first;
  final _QuantityField second;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final firstProblem = problemFor(problems, first.field);
    final secondProblem = problemFor(problems, second.field);
    final shownProblem = firstProblem ?? secondProblem;

    Widget fieldOf(_QuantityField quantity, {required bool hasProblem}) =>
        BoxedTextField(
          controller: quantity.controller,
          focusNode: quantity.focusNode,
          label: quantity.label,
          width: WebLayout.timeFieldWidth,
          valueStyle: numeralSmallStyle.copyWith(fontSize: 17),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          hasProblem: hasProblem,
          normalize: _normalizedDecimal,
        );

    return EditorFieldRow(
      label: label,
      problemText: shownProblem == null
          ? null
          : fieldProblemText(l10n, shownProblem),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          fieldOf(first, hasProblem: firstProblem != null),
          fieldOf(second, hasProblem: secondProblem != null),
        ],
      ),
    );
  }

  static String? _normalizedDecimal(String text) =>
      switch (parseDecimal(text)) {
        Ok(value: final double value) => formatFormDecimal(value),
        _ => null,
      };
}

/// A szélirány lenyíló listája: „nincs megadva" és a 16 égtáj (K12).
class _WindPointDropdown extends StatelessWidget {
  const _WindPointDropdown({required this.windPoint});

  final ValueNotifier<CompassPoint?> windPoint;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = statusLabelStyle.copyWith(
      fontSize: 9,
      color: scheme.onSurfaceVariant,
    );

    return DropdownButtonFormField<CompassPoint?>(
      initialValue: windPoint.value,
      isExpanded: true,
      onChanged: (selected) => windPoint.value = selected,
      style: numeralSmallStyle.copyWith(
        fontSize: 17,
        color: scheme.onSurface,
      ),
      dropdownColor: scheme.surfaceContainerHigh,
      decoration: InputDecoration(
        labelText: l10n.editWindFromCaps,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: labelStyle,
        floatingLabelStyle: labelStyle,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
      ),
      items: [
        DropdownMenuItem<CompassPoint?>(
          child: Text(
            l10n.editWindDirectionNone,
            style: supportTextStyle.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        for (final point in CompassPoint.values)
          DropdownMenuItem<CompassPoint?>(
            value: point,
            child: Text(compassPointLabel(point)),
          ),
      ],
    );
  }
}
