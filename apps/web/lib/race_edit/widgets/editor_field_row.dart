import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';

/// A szerkesztő egy sora: balra a címke a 132 px-es oszlopban, jobbra a
/// mező, alatta a hibaüzenet (ADR 0048 Addendum 1 G4).
///
/// A [caption] a címke alatti verzál jel (pl. „KÖTELEZŐ", „SZÁMOLT").
/// A [problemText] a mező alatt, pirossal jelenik meg (13n).
class EditorFieldRow extends StatelessWidget {
  /// Sor a [label] címkével és a [child] mezővel.
  const EditorFieldRow({
    required this.label,
    required this.child,
    this.caption,
    this.problemText,
    super.key,
  });

  /// A sor címkéje.
  final String label;

  /// A mező vagy a mezők.
  final Widget child;

  /// Verzál jel a címke alatt.
  final String? caption;

  /// A mező hibája, ha van.
  final String? problemText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final caption = this.caption;
    final problemText = this.problemText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: WebLayout.editorLabelWidth,
            // A címke a 54 px-es mező közepéhez igazodik.
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: supportTextStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      caption,
                      style: statusLabelStyle.copyWith(
                        fontSize: 8.5,
                        color: tones.low,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                child,
                if (problemText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    problemText,
                    style: supportTextStyle.copyWith(
                      fontSize: 11.5,
                      color: scheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
