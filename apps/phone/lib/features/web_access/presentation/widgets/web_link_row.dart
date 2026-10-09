import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// Egy továbbvivő sor a „Fiók" képernyő alján: felirat, halk mono érték
/// és nyíl, alatta hairline (makett 18l, 18l-2).
class WebLinkRow extends StatelessWidget {
  /// Sor a [label] felirattal és az opcionális [value] értékkel.
  const WebLinkRow({
    required this.label,
    required this.onTap,
    this.value,
    super.key,
  });

  /// A sor magassága a makett szerint.
  static const double height = 57;

  /// A felirat.
  final String label;

  /// A halk érték a nyíl előtt (pl. „4", „1 kérelem"), ha van.
  final String? value;

  /// A megnyitás.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final shownValue = value;
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              spacing: 10,
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: supportTextStyle.copyWith(
                      fontSize: 15,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (shownValue != null)
                  Text(
                    shownValue,
                    style: numeralCaptionStyle.copyWith(
                      fontSize: 12,
                      color: tones.low,
                    ),
                  ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
