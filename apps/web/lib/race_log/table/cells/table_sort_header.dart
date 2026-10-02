import 'package:flutter/material.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_padding.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_styles.dart';
import 'package:foretack_web/race_log/table/sort_direction.dart';

/// Egy kattintható oszlopfejléc (G2): kattintás vagy Enter rendez.
///
/// A rendezett oszlopot csak a fejléc jelöli: világos felirat, nyíl, 2 px-es
/// alsó vonal és kiemelt háttér. A rendezés iránya a szemantikai címkében
/// szerepel, mert a Flutterben nincs `aria-sort` (K29).
class TableSortHeader extends StatelessWidget {
  /// Fejléc a [label] felirattal; [sortedDirection] a rendezés iránya, ha
  /// ez az oszlop a rendezett.
  const TableSortHeader({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.sortedDirection,
    this.isAlignedEnd = false,
    super.key,
  });

  /// A verzál felirat.
  final String label;

  /// A felolvasott címke, a rendezett oszlopnál az iránnyal.
  final String semanticLabel;

  /// A rendezés iránya, ha ez a rendezett oszlop; különben `null`.
  final SortDirection? sortedDirection;

  /// Igaz a szám-oszlopokon: a felirat jobbra zár, mint a számok.
  final bool isAlignedEnd;

  /// A fejléc kattintása.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final direction = sortedDirection;
    final isSorted = direction != null;
    final color = isSorted ? scheme.onSurface : scheme.onSurfaceVariant;
    final text = Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        style: tableHeaderStyle.copyWith(color: color),
      ),
    );
    final arrow = Icon(
      direction == SortDirection.ascending
          ? Icons.arrow_upward
          : Icons.arrow_downward,
      size: 12,
      color: color,
    );

    return Semantics(
      button: true,
      label: semanticLabel,
      // A gyerekek szemantikája kimarad (a felirat a címkében van), ezért
      // a koppintás-akciót itt kell megadni, hogy felolvasóval is rendezzen.
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: isSorted ? scheme.surfaceContainer : scheme.surface,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: isSorted
                  ? Border(
                      bottom: BorderSide(color: scheme.onSurface, width: 2),
                    )
                  : null,
            ),
            child: TableCellPadding(
              alignment: isAlignedEnd
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSorted && isAlignedEnd) ...[
                    arrow,
                    const SizedBox(width: 2),
                  ],
                  text,
                  if (isSorted && !isAlignedEnd) ...[
                    const SizedBox(width: 2),
                    arrow,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
