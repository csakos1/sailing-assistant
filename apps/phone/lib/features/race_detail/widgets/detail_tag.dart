import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// Egy verzál mono címke a részlet pálya-sorainak jobb szélén (makett
/// 32a–b): keretes („RAJTHELY") vagy kitöltött („AKTÍV").
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja.
class DetailTag extends StatelessWidget {
  /// Egy címke.
  const DetailTag({required this.label, this.isFilled = false, super.key});

  /// A már verzál felirat.
  final String label;

  /// Igaz, ha `primary` háttérrel kitöltött (az aktív bója).
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    if (isFilled) {
      return ColoredBox(
        color: scheme.primary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: Text(
            label,
            style: numeralCaptionStyle.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: scheme.onPrimary,
            ),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: numeralCaptionStyle.copyWith(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.76,
            color: tones.low,
          ),
        ),
      ),
    );
  }
}
