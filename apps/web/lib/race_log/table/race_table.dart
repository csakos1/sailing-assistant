import 'dart:math' as math;

import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_detail/detail_formatters.dart';
import 'package:foretack_web/race_log/table/cells/table_group_label.dart';
import 'package:foretack_web/race_log/table/cells/table_name_cell.dart';
import 'package:foretack_web/race_log/table/cells/table_placing_cell.dart';
import 'package:foretack_web/race_log/table/cells/table_sort_header.dart';
import 'package:foretack_web/race_log/table/cells/table_value_cell.dart';
import 'package:foretack_web/race_log/table/cells/table_year_label.dart';
import 'package:foretack_web/race_log/table/race_table_column.dart';
import 'package:foretack_web/race_log/table/race_table_formatters.dart';
import 'package:foretack_web/race_log/table/race_table_items.dart';
import 'package:foretack_web/race_log/table/race_table_row.dart';
import 'package:foretack_web/race_log/table/race_table_sort.dart';
import 'package:foretack_web/race_log/table/sort_direction.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// A napló Táblázat nézete (ADR 0048 Addendum 1 G2, Addendum 4 K25–K31).
///
/// Két rögzített fejlécsor és két rögzített oszlop (Dátum, Verseny); a
/// többi vízszintesen görget, ha nem fér el. A sorok és a rendezés a
/// hívótól jönnek, a widget csak a görgetést és a hovert tartja.
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class RaceTable extends StatefulWidget {
  /// Táblázat az [items] sorokkal, a [sort] rendezéssel.
  const RaceTable({
    required this.items,
    required this.sort,
    required this.onSortTap,
    required this.onOpen,
    super.key,
  });

  /// A törzs sorai, rendezve, évsorokkal (`raceTableItemsOf`).
  final List<RaceTableItem> items;

  /// A jelenlegi rendezés.
  final RaceTableSort sort;

  /// Egy oszlopfejléc kattintása.
  final ValueChanged<RaceTableColumn> onSortTap;

  /// Egy versenysor kattintása: a részletező nyitása.
  final ValueChanged<RaceSummary> onOpen;

  @override
  State<RaceTable> createState() => _RaceTableState();
}

// A két fejlécsor a sorindexek elején.
const int _headerRowCount = 2;

// Az oszlopok szélessége a G2 táblázata szerint: összesen 1400 px. A Díj
// legalább ennyi, de kitölti a maradékot (K29).
const Map<RaceTableColumn, double> _columnWidths = {
  RaceTableColumn.date: 104,
  RaceTableColumn.name: 216,
  RaceTableColumn.classPlace: 80,
  RaceTableColumn.overallPlace: 80,
  RaceTableColumn.monohullPlace: 80,
  RaceTableColumn.ysNumber: 64,
  RaceTableColumn.start: 72,
  RaceTableColumn.finish: 88,
  RaceTableColumn.elapsed: 88,
  RaceTableColumn.distance: 72,
  RaceTableColumn.avgSpeed: 56,
  RaceTableColumn.maxSpeed: 56,
  RaceTableColumn.avgWind: 64,
  RaceTableColumn.maxWind: 64,
  RaceTableColumn.windDirection: 64,
  RaceTableColumn.prize: 152,
};

// A csoportsor összevont cellái: első oszlop és szélesség. Az összevont
// cella nem lóghat át a rögzített határon (K25), ezért a VERSENY csoport
// pontosan a rögzített blokk.
typedef _ColumnGroup = ({int start, int span});

const List<_ColumnGroup> _columnGroups = [
  (start: 0, span: 2),
  (start: 2, span: 4),
  (start: 6, span: 4),
  (start: 10, span: 5),
  (start: 15, span: 1),
];

// A Díjon kívüli oszlopok szélessége: 1400 − 152.
final double _otherColumnsWidth = _columnWidths.entries
    .where((entry) => entry.key != RaceTableColumn.prize)
    .fold(0, (sum, entry) => sum + entry.value);

// A csoportok első oszlopai, a bal blokk utániak: ezek előtt áll a
// csoport-elválasztó vonal.
const Set<RaceTableColumn> _groupStarts = {
  RaceTableColumn.start,
  RaceTableColumn.avgSpeed,
  RaceTableColumn.prize,
};

class _RaceTableState extends State<RaceTable> {
  final ScrollController _vertical = ScrollController();
  final ScrollController _horizontal = ScrollController();

  // A hover alatti törzs-sor indexe az `items`-ben, vagy `null`.
  int? _hoveredItem;

  @override
  void didUpdateWidget(RaceTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Új rendezésnél a régi index már más sort jelölne.
    if (!identical(oldWidget.items, widget.items)) _hoveredItem = null;
  }

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = WebLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = clampDouble(
          constraints.maxWidth - 2 * WebLayout.tableInset,
          0,
          WebLayout.tableMaxWidth,
        );
        // A Díj kitölti a maradékot (K29). A `RemainingTableSpanExtent` itt
        // nem jó: a nem rögzített oszlopoknál a megelőző szélességből
        // kimarad a rögzített blokk, így 320 px-lel túl széles lenne.
        // A `!` biztonságos: a térkép minden oszlopot tartalmaz.
        final prizeWidth = math.max(
          _columnWidths[RaceTableColumn.prize]!,
          width - _otherColumnsWidth,
        );
        return Listener(
          // A táblázaton kívüli sávokban is görgessen a görgő (K29).
          behavior: HitTestBehavior.opaque,
          onPointerSignal: _forwardWheelToTable,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: ScrollConfiguration(
                // A görgetősávokat kézzel kötjük be, a csomag példája
                // szerint; az alapértelmezettek kétszer rajzolnának.
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: Scrollbar(
                  controller: _horizontal,
                  thumbVisibility: true,
                  thickness: WebLayout.tableScrollbarThickness,
                  child: Scrollbar(
                    controller: _vertical,
                    child: TableView.builder(
                      verticalDetails: ScrollableDetails.vertical(
                        controller: _vertical,
                      ),
                      horizontalDetails: ScrollableDetails.horizontal(
                        controller: _horizontal,
                      ),
                      pinnedRowCount: _headerRowCount,
                      pinnedColumnCount: RaceTableColumn.pinnedCount,
                      columnCount: RaceTableColumn.values.length,
                      rowCount: _headerRowCount + widget.items.length,
                      columnBuilder: (index) =>
                          _columnSpan(scheme, index, prizeWidth),
                      rowBuilder: (index) => _rowSpan(scheme, index),
                      cellBuilder: (_, vicinity) => _cell(l10n, vicinity),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // A táblázaton belül a táblázat saját görgetője jelentkezik előbb, így
  // a feloldó őt választja; kívül csak ez a kérés van.
  void _forwardWheelToTable(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
      if (resolved is! PointerScrollEvent || !_vertical.hasClients) return;
      _vertical.position.pointerScroll(resolved.scrollDelta.dy);
    });
  }

  TableSpan _columnSpan(ColorScheme scheme, int index, double prizeWidth) {
    final column = RaceTableColumn.values[index];
    final leading = _groupStarts.contains(column)
        ? BorderSide(color: scheme.outlineVariant)
        : BorderSide.none;
    final trailing = column == RaceTableColumn.name
        ? BorderSide(color: scheme.outline)
        : BorderSide.none;
    final hasLine = leading != BorderSide.none || trailing != BorderSide.none;
    // A vonalak előtér-dekorációk: a sor-hátterek fölé kerülnek (K29).
    final lines = hasLine
        ? TableSpanDecoration(
            border: TableSpanBorder(leading: leading, trailing: trailing),
          )
        : null;
    // A `!` biztonságos: a térkép minden oszlopot tartalmaz.
    final width = column == RaceTableColumn.prize
        ? prizeWidth
        : _columnWidths[column]!;
    return TableSpan(
      extent: FixedTableSpanExtent(width),
      foregroundDecoration: lines,
    );
  }

  TableSpan _rowSpan(ColorScheme scheme, int index) {
    if (index == 0) {
      return TableSpan(
        extent: const FixedTableSpanExtent(WebLayout.tableGroupRowHeight),
        backgroundDecoration: _rowDecoration(scheme.surface, scheme),
      );
    }
    if (index == 1) {
      return TableSpan(
        extent: const FixedTableSpanExtent(WebLayout.tableHeaderRowHeight),
        backgroundDecoration: _rowDecoration(scheme.surface, scheme),
        // A fejléc-cellák átlátszatlanok (a rendezett cella kiemelt): az
        // alsó vonal ezért előtér, különben eltakarnák.
        foregroundDecoration: TableSpanDecoration(
          border: TableSpanBorder(trailing: BorderSide(color: scheme.outline)),
        ),
      );
    }
    final itemIndex = index - _headerRowCount;
    return switch (widget.items[itemIndex]) {
      TableYearItem() => TableSpan(
        extent: const FixedTableSpanExtent(WebLayout.tableYearRowHeight),
        backgroundDecoration: _rowDecoration(
          scheme.surface,
          scheme,
          line: scheme.outline,
        ),
      ),
      TableRaceItem(:final row, :final isAlternate) => TableSpan(
        extent: const FixedTableSpanExtent(WebLayout.tableRowHeight),
        backgroundDecoration: _rowDecoration(
          _hoveredItem == itemIndex
              ? scheme.surfaceContainerHigh
              : isAlternate
              ? scheme.surfaceContainer
              : scheme.surface,
          scheme,
        ),
        cursor: SystemMouseCursors.click,
        // A `MouseTracker` a nézetváltás után még hívhatja: `mounted`.
        onEnter: (_) {
          if (mounted) setState(() => _hoveredItem = itemIndex);
        },
        onExit: (_) {
          if (mounted && _hoveredItem == itemIndex) {
            setState(() => _hoveredItem = null);
          }
        },
        recognizerFactories: {
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                TapGestureRecognizer.new,
                (recognizer) =>
                    recognizer.onTap = () => widget.onOpen(row.summary),
              ),
        },
      ),
    };
  }

  // A sor háttere és alsó hajszálvonala (G2: a hairline a csíkozás mellett
  // is marad).
  TableSpanDecoration _rowDecoration(
    Color color,
    ColorScheme scheme, {
    Color? line,
  }) => TableSpanDecoration(
    color: color,
    border: TableSpanBorder(
      trailing: BorderSide(color: line ?? scheme.outlineVariant),
    ),
  );

  TableViewCell _cell(WebLocalizations l10n, TableVicinity vicinity) {
    final column = RaceTableColumn.values[vicinity.column];
    if (vicinity.row == 0) return _groupCell(l10n, vicinity.column);
    if (vicinity.row == 1) return TableViewCell(child: _header(l10n, column));
    return switch (widget.items[vicinity.row - _headerRowCount]) {
      TableYearItem(:final year, :final raceCount) => _yearCell(
        vicinity.column,
        year,
        raceCount,
      ),
      TableRaceItem(:final row) => TableViewCell(
        child: _raceCell(l10n, row, column),
      ),
    };
  }

  // Az összevont cella minden érintett vicinitásra ugyanazt adja vissza,
  // különben görgetéskor szétválna (a `TableView` szerződése).
  TableViewCell _groupCell(WebLocalizations l10n, int columnIndex) {
    final group = _columnGroups.lastWhere((g) => g.start <= columnIndex);
    final label = switch (group.start) {
      0 => l10n.tableGroupRaceCaps,
      2 => l10n.tableGroupResultCaps,
      6 => l10n.tableGroupTimeCaps,
      10 => l10n.tableGroupSpeedCaps,
      _ => l10n.tableGroupPrizeCaps,
    };
    return TableViewCell(
      columnMergeStart: group.start,
      columnMergeSpan: group.span,
      child: TableGroupLabel(text: label),
    );
  }

  TableViewCell _yearCell(int columnIndex, int year, int raceCount) {
    if (columnIndex < RaceTableColumn.pinnedCount) {
      return TableViewCell(
        columnMergeStart: 0,
        columnMergeSpan: RaceTableColumn.pinnedCount,
        child: TableYearLabel(year: year, raceCount: raceCount),
      );
    }
    return TableViewCell(
      columnMergeStart: RaceTableColumn.pinnedCount,
      columnMergeSpan:
          RaceTableColumn.values.length - RaceTableColumn.pinnedCount,
      child: const SizedBox.shrink(),
    );
  }

  Widget _header(WebLocalizations l10n, RaceTableColumn column) {
    final label = _columnLabel(l10n, column);
    final sort = widget.sort;
    final sortedDirection = sort.column == column ? sort.direction : null;
    return TableSortHeader(
      label: label,
      semanticLabel: switch (sortedDirection) {
        SortDirection.ascending => l10n.tableSortedAscending(label),
        SortDirection.descending => l10n.tableSortedDescending(label),
        null => label,
      },
      sortedDirection: sortedDirection,
      isAlignedEnd: _isNumeric(column),
      onTap: () => widget.onSortTap(column),
    );
  }

  Widget _raceCell(
    WebLocalizations l10n,
    RaceTableRow row,
    RaceTableColumn column,
  ) {
    final isApproximate = row.areStatsApproximate;
    return switch (column) {
      RaceTableColumn.date => TableValueCell(
        value: formatTableDate(row.day),
        isAlignedEnd: false,
      ),
      RaceTableColumn.name => TableNameCell(
        name: row.name,
        manualLabel: row.isManual ? l10n.tableManualCaps : null,
      ),
      RaceTableColumn.classPlace => _placingCell(row.classPlace),
      RaceTableColumn.overallPlace => _placingCell(row.overallPlace),
      RaceTableColumn.monohullPlace => _placingCell(row.monohullPlace),
      RaceTableColumn.ysNumber => _optional(
        row.ysNumberHundredths,
        (ys) => TableValueCell(value: formatYsNumber(ys)),
      ),
      RaceTableColumn.start => _optional(
        row.start,
        (start) => TableValueCell(
          value: formatTableClock(start.instant),
          isApproximate: start.isApproximate,
        ),
      ),
      RaceTableColumn.finish => _optional(
        row.finish,
        (finish) => TableValueCell(
          value: formatTableClock(finish.instant),
          isApproximate: finish.isApproximate,
          suffix: row.isFinishNextDay ? l10n.tableNextDay : null,
        ),
      ),
      RaceTableColumn.elapsed => _optional(
        row.elapsed,
        (elapsed) => TableValueCell(
          value: formatElapsed(elapsed.value),
          isApproximate: elapsed.isApproximate,
        ),
      ),
      RaceTableColumn.distance => _optional(
        row.distanceMeters,
        (meters) => TableValueCell(
          value: formatTableKilometers(meters),
          isApproximate: isApproximate,
        ),
      ),
      RaceTableColumn.avgSpeed => _knotsCell(row.avgSpeedMps, isApproximate),
      RaceTableColumn.maxSpeed => _knotsCell(row.maxSpeedMps, isApproximate),
      RaceTableColumn.avgWind => _knotsCell(row.avgWindMps, isApproximate),
      RaceTableColumn.maxWind => _knotsCell(row.maxWindMps, isApproximate),
      RaceTableColumn.windDirection => _optional(
        row.windPoint,
        (point) => TableValueCell(
          value: compassPointLabel(point),
          isApproximate: isApproximate,
        ),
      ),
      RaceTableColumn.prize => _optional(
        row.prize,
        (prize) => TableValueCell(value: prize, isAlignedEnd: false),
      ),
    };
  }

  Widget _placingCell(TablePlacing? placing) =>
      _optional(placing, (value) => TablePlacingCell(placing: value));

  Widget _knotsCell(double? metersPerSecond, bool isApproximate) => _optional(
    metersPerSecond,
    (value) => TableValueCell(
      value: formatTableKnots(value),
      isApproximate: isApproximate,
    ),
  );

  // Üres cellában semmi nem áll (G2).
  static Widget _optional<T extends Object>(
    T? value,
    Widget Function(T value) build,
  ) => value == null ? const SizedBox.shrink() : build(value);

  static bool _isNumeric(RaceTableColumn column) => switch (column) {
    RaceTableColumn.date ||
    RaceTableColumn.name ||
    RaceTableColumn.windDirection ||
    RaceTableColumn.prize => false,
    _ => true,
  };

  static String _columnLabel(
    WebLocalizations l10n,
    RaceTableColumn column,
  ) => switch (column) {
    RaceTableColumn.date => l10n.tableColumnDateCaps,
    RaceTableColumn.name => l10n.tableColumnNameCaps,
    RaceTableColumn.classPlace => l10n.tableColumnClassCaps,
    RaceTableColumn.overallPlace => l10n.tableColumnOverallCaps,
    RaceTableColumn.monohullPlace => l10n.tableColumnMonohullCaps,
    RaceTableColumn.ysNumber => l10n.tableColumnYsCaps,
    RaceTableColumn.start => l10n.tableColumnStartCaps,
    RaceTableColumn.finish => l10n.tableColumnFinishCaps,
    RaceTableColumn.elapsed => l10n.tableColumnElapsedCaps,
    RaceTableColumn.distance => l10n.tableColumnDistanceCaps,
    RaceTableColumn.avgSpeed => l10n.tableColumnAvgSpeedCaps,
    RaceTableColumn.maxSpeed => l10n.tableColumnMaxSpeedCaps,
    RaceTableColumn.avgWind => l10n.tableColumnAvgWindCaps,
    RaceTableColumn.maxWind => l10n.tableColumnMaxWindCaps,
    RaceTableColumn.windDirection => l10n.tableColumnDirectionCaps,
    RaceTableColumn.prize => l10n.tableColumnPrizeCaps,
  };
}
