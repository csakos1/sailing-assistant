import 'package:flutter/material.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_padding.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_styles.dart';

/// Egy szám- vagy szöveg-cella. A közelítő értéket `~` előjel és tompított
/// szín jelöli (G6); a jelentést a `~` hordozza, nem a szín.
class TableValueCell extends StatelessWidget {
  /// Cella a [value] szöveggel.
  const TableValueCell({
    required this.value,
    this.isApproximate = false,
    this.isAlignedEnd = true,
    this.suffix,
    super.key,
  });

  /// A formázott érték.
  final String value;

  /// Igaz, ha az érték a rögzítésből jön, nem a hivatalos ablakból.
  final bool isApproximate;

  /// Igaz a számoknál: jobbra zárnak (G2).
  final bool isAlignedEnd;

  /// Kis kiegészítő jel az érték után, pl. a másnapi befutás „+1"-e.
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isApproximate ? scheme.onSurfaceVariant : scheme.onSurface;
    final suffixText = suffix;
    return TableCellPadding(
      alignment: isAlignedEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          text: isApproximate ? '~$value' : value,
          children: [
            if (suffixText != null)
              TextSpan(
                text: ' $suffixText',
                style: tableNumberStyle.copyWith(
                  fontSize: 9,
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        style: tableNumberStyle.copyWith(color: color),
      ),
    );
  }
}
