import 'package:flutter/material.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_padding.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_styles.dart';

/// A Statisztika-képernyő egy táblájának oszlopa.
///
/// A `width` `null`-ja a maradék szélességet kéri; a számoszlop jobbra
/// zár, Martian Mono számokkal, a szövegoszlop balra (G2).
typedef SeasonTableColumn = ({
  String label,
  String? unit,
  double? width,
  bool isNumeric,
});

/// Kis, rögzített tábla a Statisztika-képernyőn (ADR 0049 Addendum 1 P2,
/// P5), a napló táblázatának tipográfiájával és színeivel (G7).
///
/// Néhány soros, ezért nem görget és nem rendez: a Flutter `Table`-je
/// elég, a `TableView` lusta építése itt nem kell.
class SeasonTable extends StatelessWidget {
  /// Tábla a `columns` fejléccel és a `rows` soraival.
  const SeasonTable({required this.columns, required this.rows, super.key});

  /// Az oszlopok, balról jobbra.
  final List<SeasonTableColumn> columns;

  /// A sorok kész szövegei, oszloponként; a hiányzó érték a hiányjel.
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      // A cellák betétével együtt a szöveg a szakaszcímmel egy vonalban áll.
      padding: const EdgeInsets.symmetric(
        horizontal: WebLayout.columnInset - WebLayout.tableCellInset,
      ),
      child: Table(
        columnWidths: {
          for (final (index, column) in columns.indexed)
            index: switch (column.width) {
              final double width => FixedColumnWidth(width),
              null => const FlexColumnWidth(),
            },
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(bottom: BorderSide(color: scheme.outline)),
            ),
            children: [
              for (final column in columns) _HeaderCell(column: column),
            ],
          ),
          for (final (index, row) in rows.indexed)
            TableRow(
              // Váltakozó sorszín, mint a napló táblázatában (36).
              decoration: BoxDecoration(
                color: index.isOdd ? scheme.surfaceContainer : scheme.surface,
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              children: [
                for (final (column, value) in _cellsOf(row))
                  _ValueCell(value: value, isNumeric: column.isNumeric),
              ],
            ),
        ],
      ),
    );
  }

  // Egy sor cellái a saját oszlopukkal párban.
  List<(SeasonTableColumn, String)> _cellsOf(List<String> row) => [
    for (final (index, column) in columns.indexed) (column, row[index]),
  ];
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.column});

  final SeasonTableColumn column;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unit = column.unit;
    return SizedBox(
      height: WebLayout.tableHeaderRowHeight,
      child: TableCellPadding(
        alignment: column.isNumeric
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: column.isNumeric
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              column.label,
              maxLines: 1,
              style: tableHeaderStyle.copyWith(color: scheme.onSurfaceVariant),
            ),
            // A mértékegység a fejléc második sorában (L5).
            if (unit != null)
              Text(
                unit,
                maxLines: 1,
                style: tableUnitStyle.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({required this.value, required this.isNumeric});

  final String value;
  final bool isNumeric;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final style = isNumeric ? tableNumberStyle : tableNameStyle;
    return SizedBox(
      height: WebLayout.tableRowHeight,
      child: TableCellPadding(
        alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: style.copyWith(color: color),
        ),
      ),
    );
  }
}
