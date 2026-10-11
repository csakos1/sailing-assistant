import 'package:flutter/material.dart';
import 'package:foretack_ui/src/theme/foretack_typography.dart';
import 'package:foretack_ui/src/theme/text_tones.dart';

/// A dialógus érintett eleme egy sorban (makett 35d / 11a): opcionális
/// sorszám, név és opcionális mono adat (pl. `02` · `Tihany` vagy
/// `58. Kékszalag` · `4 BÓJA`).
typedef ForetackDialogSubject = ({
  String? leading,
  String name,
  String? trailing,
});

/// A dialógus 42 dp-s adatsor-cellája: mi érintett (ADR 0056 D5, makett
/// 35d).
///
/// Keretes doboz `surface` háttérrel; balra a halk mono sorszám, középen
/// a név, jobbra a halk mono adat. A hosszú név levágódik, a két mono
/// rész mindig látszik.
class ForetackDialogSubjectCell extends StatelessWidget {
  /// Cella a [subject] elemmel.
  const ForetackDialogSubjectCell({required this.subject, super.key});

  /// A cella magassága (makett 35d).
  static const double height = 42;

  /// Az érintett elem.
  final ForetackDialogSubject subject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // A `foretackTheme` mindig regisztrálja a `TextTones`-t.
    final tones = theme.extension<TextTones>()!;
    final leading = subject.leading;
    final trailing = subject.trailing;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline),
      ),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            spacing: 12,
            children: [
              if (leading != null)
                Text(
                  leading,
                  style: numeralCaptionStyle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tones.low,
                  ),
                ),
              Expanded(
                child: Text(
                  subject.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: supportTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing,
                  style: numeralCaptionStyle.copyWith(
                    fontSize: 11,
                    color: tones.low,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
