import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';

/// Számozott szakaszcím a Statisztika-képernyőn (15a): „01 AZ ÉVAD".
///
/// A [trailing] halk felirat jobbra zárva áll (16a, 16b): „15 verseny ·
/// időrendben".
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja.
class SeasonSectionHeading extends StatelessWidget {
  /// Szakaszcím a [number] sorszámmal és a verzál [title]-lel.
  const SeasonSectionHeading({
    required this.number,
    required this.title,
    this.trailing,
    super.key,
  });

  /// A szakasz sorszáma (1-től).
  final int number;

  /// A verzál cím.
  final String title;

  /// A jobb oldali halk felirat; `null`, ha nincs.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailingText = trailing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WebLayout.columnInset,
        40,
        WebLayout.columnInset,
        16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            number.toString().padLeft(2, '0'),
            style: numeralCaptionStyle.copyWith(
              color: theme.extension<TextTones>()!.low,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: sectionLabelStyle.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (trailingText != null) ...[
            const Spacer(),
            Text(
              trailingText,
              style: supportTextStyle.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
