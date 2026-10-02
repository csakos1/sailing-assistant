import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_edit/widgets/editor_field_row.dart';

/// Egy csak olvasható, az űrlapból számolt sor, pl. a menetidő (ADR 0048
/// Addendum 1 G4, Addendum 4 K11).
///
/// A címke alatt „SZÁMOLT" áll. Hiányzó adatnál „—" és az [explanation],
/// hogy miből lesz az érték.
class ComputedValueRow extends StatelessWidget {
  /// Sor a [label] címkével és a [value] értékkel.
  const ComputedValueRow({
    required this.label,
    required this.value,
    required this.explanation,
    super.key,
  });

  /// A sor címkéje.
  final String label;

  /// A számolt érték szövege, vagy `null`, ha még nem számolható.
  final String? value;

  /// Miből számolódik (verzál), a hiányjel mellett.
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final value = this.value;

    return EditorFieldRow(
      label: label,
      caption: l10n.editComputedCaps,
      child: SizedBox(
        height: WebLayout.editorFieldHeight,
        child: Row(
          children: [
            Text(
              value ?? missingValueLabel,
              style: numeralSmallStyle.copyWith(
                fontSize: 17,
                color: value == null ? tones.low : scheme.onSurface,
              ),
            ),
            if (value == null) ...[
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  explanation,
                  style: statusLabelStyle.copyWith(
                    fontSize: 9,
                    color: tones.low,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
