import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_styles.dart';
import 'package:foretack_web/race_log/table/race_table_column.dart';
import 'package:foretack_web/race_log/table/race_table_items.dart';
import 'package:foretack_web/race_log/table/race_table_row.dart';
import 'package:foretack_web/race_log/table/table_cell_value.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy helyezés-oszlop két helye: a jobbra zárt szám és a perjeles
/// mezőny (G2).
typedef PlacingSlots = ({double place, double fleet});

/// A táblázat oszlopszélességei a tartalomhoz mérve (ADR 0048 Addendum 5
/// L4).
typedef RaceTableWidths = ({
  Map<RaceTableColumn, double> columns,
  Map<RaceTableColumn, PlacingSlots> placingSlots,
});

/// A G2 szélességei: ezek a legkisebb szélességek. A tényleges oszlop
/// ennél szélesebb, ha a felirata vagy egy cellája nem fér el benne.
const Map<RaceTableColumn, double> raceTableMinimumWidths = {
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

/// A név oszlop legnagyobb szélessége; a hosszabb név `…`-tal vágódik,
/// hogy a rögzített bal blokk ne nyelje el a képernyőt.
const double raceTableMaxNameWidth = 400;

/// A rendezett fejléc nyila a felirat mellett (12 px + 2 px köz).
const double raceTableSortArrowWidth = 14;

/// Az [items] oszlopszélességei.
///
/// - Minden oszlop legalább a [raceTableMinimumWidths] szélessége.
/// - Fölötte a fejléc (felirat, mértékegység, rendezési nyíl) és a
///   leghosszabb cella szövege dönt, a két oldali betéttel.
/// - A Díjat nem méri: az a táblázat maradékát kapja, a hosszú díj
///   `…`-tal vágódik (a teljes szöveg a részletezőn).
///
/// A [headerLabel] és az [unitLabel] az oszlop fejlécének két sora, a
/// [manualLabel] a KÉZI címke, a [nextDayMark] a „+1".
RaceTableWidths measureRaceTableWidths({
  required List<RaceTableItem> items,
  required String Function(RaceTableColumn column) headerLabel,
  required String? Function(RaceTableColumn column) unitLabel,
  required String manualLabel,
  required String nextDayMark,
  required TextScaler textScaler,
}) {
  final measure = _TextMeasurer(textScaler);
  final rows = [
    for (final item in items)
      if (item case TableRaceItem(:final row)) row,
  ];

  final columns = <RaceTableColumn, double>{};
  final placingSlots = <RaceTableColumn, PlacingSlots>{};
  for (final column in RaceTableColumn.values) {
    // A `!` biztonságos: a térkép minden oszlopot tartalmaz.
    final minimum = raceTableMinimumWidths[column]!;
    final unit = unitLabel(column);
    final unitWidth = unit == null ? 0.0 : measure(unit, tableUnitStyle);
    final header =
        math.max(measure(headerLabel(column), tableHeaderStyle), unitWidth) +
        raceTableSortArrowWidth;

    final content = switch (column) {
      RaceTableColumn.prize => 0.0,
      RaceTableColumn.name => math.min(
        _widest(rows, (row) => _nameWidth(measure, row, manualLabel)),
        raceTableMaxNameWidth - 2 * WebLayout.tableCellInset,
      ),
      RaceTableColumn.classPlace ||
      RaceTableColumn.overallPlace ||
      RaceTableColumn.monohullPlace => _sumOf(
        placingSlots[column] = _placingSlots(measure, rows, column),
      ),
      RaceTableColumn.date ||
      RaceTableColumn.ysNumber ||
      RaceTableColumn.start ||
      RaceTableColumn.finish ||
      RaceTableColumn.elapsed ||
      RaceTableColumn.distance ||
      RaceTableColumn.avgSpeed ||
      RaceTableColumn.maxSpeed ||
      RaceTableColumn.avgWind ||
      RaceTableColumn.maxWind ||
      RaceTableColumn.windDirection => _widest(
        rows,
        (row) => _valueWidth(measure, row, column, nextDayMark),
      ),
    };
    final needed = math.max(header, content) + 2 * WebLayout.tableCellInset;
    columns[column] = math.max(minimum, needed.ceilToDouble());
  }
  return (
    columns: Map.unmodifiable(columns),
    placingSlots: Map.unmodifiable(placingSlots),
  );
}

double _widest(
  List<RaceTableRow> rows,
  double Function(RaceTableRow row) widthOf,
) => rows.fold(0, (widest, row) => math.max(widest, widthOf(row)));

double _sumOf(PlacingSlots slots) => slots.place + slots.fleet;

double _valueWidth(
  _TextMeasurer measure,
  RaceTableRow row,
  RaceTableColumn column,
  String nextDayMark,
) {
  final cell = tableCellValueOf(row, column, nextDayMark: nextDayMark);
  if (cell == null) return 0;
  final value = cell.isApproximate ? '~${cell.value}' : cell.value;
  final suffix = cell.suffix;
  // A jel a cellában kisebb betűvel, egy szóközzel áll (`TableValueCell`).
  return measure(value, tableNumberStyle) +
      (suffix == null ? 0.0 : measure(' $suffix', tableSuffixStyle));
}

double _nameWidth(_TextMeasurer measure, RaceTableRow row, String label) {
  final name = measure(row.name, tableNameStyle);
  // A KÉZI címke 8 px-es közzel áll a név után (G6).
  return row.isManual ? name + 8 + measure(label, tableGroupStyle) : name;
}

PlacingSlots _placingSlots(
  _TextMeasurer measure,
  List<RaceTableRow> rows,
  RaceTableColumn column,
) {
  var place = WebLayout.tablePlaceWidth;
  var fleet = WebLayout.tableFleetWidth;
  for (final row in rows) {
    final placing = column == RaceTableColumn.classPlace
        ? row.classPlace
        : column == RaceTableColumn.overallPlace
        ? row.overallPlace
        : row.monohullPlace;
    if (placing == null) continue;
    place = math.max(
      place,
      measure(tablePlaceText(placing.placing), tableNumberStyle),
    );
    final fleetSize = placing.fleetSize;
    if (placing.placing is FinishPlace && fleetSize != null) {
      fleet = math.max(fleet, measure('/$fleetSize', tableNumberStyle));
    }
  }
  return (place: place.ceilToDouble(), fleet: fleet.ceilToDouble());
}

/// A helyezés szövege a cellában: a szám, vagy `DNF` / `DSQ`.
String tablePlaceText(Placing placing) => switch (placing) {
  FinishPlace(:final place) => '$place',
  Dnf() => 'DNF',
  Dsq() => 'DSQ',
};

// Egy szöveg szélessége egy stílussal. A `TextPainter` csak elrendez, nem
// rajzol, és mérés után azonnal felszabadul.
class _TextMeasurer {
  _TextMeasurer(this._textScaler);

  final TextScaler _textScaler;

  double call(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: _textScaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}
