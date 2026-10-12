import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// Egy űrlap-szakasz fejléce: verzál címke, vonal, opcionális darabszám
/// (33a „RAJTHELY", „BÓJÁK 2").
///
/// A címke nem rugalmas, a vonal kitölti a maradékot: egy `Flexible`
/// címke mellett az `Expanded` vonal csak a szabad hely felét kapná (a
/// `WebSectionHeader` tanulsága). Szám nélkül a vonal 10 dp-re a margótól
/// áll meg, mint a webes fejléceké.
class FormSectionHeader extends StatelessWidget {
  /// Egy fejléc a már verzál [label]-lel és az opcionális [count]-tal.
  const FormSectionHeader({required this.label, this.count, super.key});

  /// A verzál felirat (az ARB-ben verzál).
  final String label;

  /// A szakasz elemeinek száma, vagy `null`.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final style = numeralCaptionStyle.copyWith(fontWeight: FontWeight.w600);
    final count = this.count;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        spacing: 10,
        children: [
          Text(
            label,
            style: style.copyWith(
              letterSpacing: 1.26,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 1,
              child: ColoredBox(color: scheme.outlineVariant),
            ),
          ),
          if (count == null)
            const SizedBox(width: 0)
          else
            Text('$count', style: style.copyWith(color: tones.low)),
        ],
      ),
    );
  }
}
