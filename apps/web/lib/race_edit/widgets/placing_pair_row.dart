import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_edit/editor_problems.dart';
import 'package:foretack_web/race_edit/field_problem_text.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:foretack_web/race_edit/form/form_text_parsers.dart';
import 'package:foretack_web/race_edit/form/result_form_values.dart';
import 'package:foretack_web/race_edit/placing_fields.dart';
import 'package:foretack_web/race_edit/widgets/boxed_text_field.dart';
import 'package:foretack_web/race_edit/widgets/choice_segment.dart';
import 'package:foretack_web/race_edit/widgets/editor_field_row.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Egy helyezés sora: `[helyezés] / [mezőny]` és a `[SZÁM | DNF | DSQ]`
/// szegmens (ADR 0048 Addendum 1 G4, Addendum 4 K11).
///
/// DNF/DSQ mellett a helyezés-mező tiltott, a mezőny-mező aktív. A pár
/// alatt az első hibája áll (13n, 14p).
class PlacingPairRow extends StatelessWidget {
  /// Sor a [label] címkével a [fields] mezői fölött.
  const PlacingPairRow({
    required this.label,
    required this.fields,
    required this.placeField,
    required this.fleetSizeField,
    required this.problems,
    super.key,
  });

  /// A sor címkéje (pl. „Abszolút").
  final String label;

  /// A pár mezői.
  final PlacingFields fields;

  /// A helyezés mezőjének azonosítója a hibákhoz.
  final InputField placeField;

  /// A mezőny mezőjének azonosítója a hibákhoz.
  final InputField fleetSizeField;

  /// Az űrlap összes hibája.
  final List<FieldProblem> problems;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final placeProblem = problemFor(problems, placeField);
    final fleetSizeProblem = problemFor(problems, fleetSizeField);
    final shownProblem = placeProblem ?? fleetSizeProblem;

    return ValueListenableBuilder<PlacingKind>(
      valueListenable: fields.kind,
      builder: (context, kind, _) => EditorFieldRow(
        label: label,
        problemText: shownProblem == null
            ? null
            : fieldProblemText(
                l10n,
                shownProblem,
                fleetSize: fields.fleetSize.text.trim(),
              ),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            BoxedTextField(
              controller: fields.place,
              focusNode: fields.placeFocus,
              label: l10n.editPlaceFieldCaps,
              width: WebLayout.placingFieldWidth,
              valueStyle: numeralSmallStyle,
              keyboardType: TextInputType.number,
              isEnabled: kind == PlacingKind.number,
              hasProblem: placeProblem != null,
              normalize: _trimmedNumber,
            ),
            Text(
              '/',
              style: numeralSmallStyle.copyWith(
                color: Theme.of(context).extension<TextTones>()!.low,
              ),
            ),
            BoxedTextField(
              controller: fields.fleetSize,
              focusNode: fields.fleetSizeFocus,
              label: l10n.editFleetFieldCaps,
              width: WebLayout.placingFieldWidth,
              valueStyle: numeralSmallStyle,
              keyboardType: TextInputType.number,
              hasProblem: fleetSizeProblem != null,
              normalize: _trimmedNumber,
            ),
            ChoiceSegment<PlacingKind>(
              options: [
                (value: PlacingKind.number, label: l10n.editPlacingNumberCaps),
                (value: PlacingKind.dnf, label: l10n.editPlacingDnfCaps),
                (value: PlacingKind.dsq, label: l10n.editPlacingDsqCaps),
              ],
              selected: kind,
              onSelected: (selected) => fields.kind.value = selected,
            ),
          ],
        ),
      ),
    );
  }

  // A szóközös szám a széleiről levágva; az olvashatatlan szöveg marad.
  static String? _trimmedNumber(String text) => switch (parseWholeNumber(
    text,
  )) {
    Ok(value: final int number) => '$number',
    _ => null,
  };
}
