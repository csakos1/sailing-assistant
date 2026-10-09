import 'package:flutter/material.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_padding.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_styles.dart';

/// A verseny neve, kézi versenynél utána a KÉZI címke (G6).
class TableNameCell extends StatelessWidget {
  /// Cella a [name] névvel; [manualLabel] a kézi verseny címkéje, vagy
  /// `null` a telemetriás versenynél.
  const TableNameCell({required this.name, this.manualLabel, super.key});

  /// A verseny neve.
  final String name;

  /// A KÉZI címke, vagy `null`.
  final String? manualLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = manualLabel;
    return TableCellPadding(
      child: Row(
        children: [
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: tableNameStyle.copyWith(color: scheme.onSurface),
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: tableGroupStyle.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
