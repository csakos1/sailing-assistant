import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// A szerkesztő szakaszcíme: verzál felirat és mellette egy hairline
/// (ADR 0048 Addendum 1 G4, makett 14r).
class EditorSectionLabel extends StatelessWidget {
  /// Szakaszcím a [text] felirattal.
  const EditorSectionLabel({required this.text, super.key});

  /// A verzál felirat.
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 20),
      child: Row(
        children: [
          Text(
            text,
            style: statusLabelStyle.copyWith(
              fontSize: 10.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 1,
              child: ColoredBox(color: scheme.outlineVariant),
            ),
          ),
        ],
      ),
    );
  }
}
