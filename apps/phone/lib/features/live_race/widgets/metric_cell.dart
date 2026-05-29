import 'package:flutter/material.dart';

/// Egy érték-cella: felül a címke, alatta a (gyermek) érték (§8.7).
///
/// „Dumb" widget — csak a keretet és a címkét adja; a tényleges
/// érték-megjelenítés a [child] dolga (sima szám vagy nyíl-érték).
class MetricCell extends StatelessWidget {
  /// Címke + a benne megjelenő érték-widget.
  const MetricCell({required this.label, required this.child, super.key});

  /// A cella címkéje (pl. „TWA most").
  final String label;

  /// Az érték-megjelenítő widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Align(alignment: Alignment.centerLeft, child: child),
        ],
      ),
    );
  }
}
