import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_edit/result_form_fields.dart';
import 'package:foretack_web/race_edit/widgets/boxed_text_field.dart';
import 'package:foretack_web/race_edit/widgets/editor_section_label.dart';

/// A „DÍJ ÉS ÖSSZEFOGLALÓ" szakasz: felül-címkés mezők a 640 px-es
/// mértékben (ADR 0048 Addendum 1 G4).
class PrizeAndSummarySection extends StatelessWidget {
  /// Szakasz a [fields] díj- és összefoglaló-mezője fölött.
  const PrizeAndSummarySection({required this.fields, super.key});

  /// Az eredmény-űrlap mezői.
  final ResultFormFields fields;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final titleStyle = supportTextStyle.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    );
    final labelStyle = statusLabelStyle.copyWith(
      fontSize: 9,
      color: scheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSectionLabel(text: l10n.editSectionPrizeSummaryCaps),
        Text(l10n.editPrize, style: titleStyle),
        const SizedBox(height: 14),
        BoxedTextField(
          controller: fields.prize,
          label: l10n.editPrizeFieldCaps,
          hint: l10n.editPrizeHint,
          isCentered: false,
        ),
        const SizedBox(height: 24),
        Text(l10n.editSummary, style: titleStyle),
        const SizedBox(height: 14),
        TextField(
          controller: fields.summary,
          minLines: 8,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: supportTextStyle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.65,
            color: scheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: l10n.editSummaryFieldCaps,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelStyle: labelStyle,
            floatingLabelStyle: labelStyle,
            hintText: l10n.editSummaryHint,
            hintStyle: supportTextStyle.copyWith(color: tones.low),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
