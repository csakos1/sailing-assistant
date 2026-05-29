import 'package:flutter/material.dart';

/// Egy nagy, tabular-figures érték-szöveg az érték-cellákhoz (§8.7).
///
/// Tabular figures, hogy a számok ne ugráljanak 1 Hz-en. A [color]
/// felülírható (confidence vagy „—" tompítás); null esetén a téma
/// onSurface színe.
class MetricValueText extends StatelessWidget {
  /// A (már formázott) érték + opcionális szín.
  const MetricValueText(this.text, {this.color, super.key});

  /// A megjelenítendő, már formázott érték.
  final String text;

  /// Opcionális szín; null esetén a téma onSurface színe.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.displaySmall?.copyWith(
        color: color ?? theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
