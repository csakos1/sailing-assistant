import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// Egy kis keretes, mono címke (a belépés módja: `QR`, `JELSZÓ`, `KÓD`,
/// ADR 0051 Addendum 1 H9, makett 18i).
class WebModeTag extends StatelessWidget {
  /// Címke a [label] (verzál) szöveggel.
  const WebModeTag({required this.label, super.key});

  /// A verzál felirat.
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: statusLabelStyle.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
