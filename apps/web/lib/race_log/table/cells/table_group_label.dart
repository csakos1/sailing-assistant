import 'package:flutter/material.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_padding.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_styles.dart';

/// A csoportsor egy összevont cellájának felirata.
class TableGroupLabel extends StatelessWidget {
  /// Felirat a [text] szöveggel.
  const TableGroupLabel({required this.text, super.key});

  /// A csoport neve verzállal.
  final String text;

  @override
  Widget build(BuildContext context) => TableCellPadding(
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.clip,
      softWrap: false,
      style: tableGroupStyle.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
