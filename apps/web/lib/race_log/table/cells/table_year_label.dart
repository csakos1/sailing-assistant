import 'package:flutter/material.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_padding.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_styles.dart';

/// Az évsor a rögzített blokkban: az év és a versenyei száma (G2).
class TableYearLabel extends StatelessWidget {
  /// Évsor a [year] évhez, [raceCount] versennyel.
  const TableYearLabel({
    required this.year,
    required this.raceCount,
    super.key,
  });

  /// Az év.
  final int year;

  /// Az év versenyeinek száma.
  final int raceCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TableCellPadding(
      child: Row(
        children: [
          Text(
            '$year',
            style: tableNumberStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$raceCount',
            style: tableNumberStyle.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
