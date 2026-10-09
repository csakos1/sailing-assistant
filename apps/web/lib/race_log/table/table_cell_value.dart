import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/race_detail/detail_formatters.dart';
import 'package:foretack_web/race_log/table/race_table_column.dart';
import 'package:foretack_web/race_log/table/race_table_formatters.dart';
import 'package:foretack_web/race_log/table/race_table_row.dart';

/// Egy szöveges cella tartalma (ADR 0048 Addendum 5 L4).
///
/// A rajzolás és az oszlopszélesség mérése ugyanebből dolgozik, így a
/// mért szöveg pontosan az, ami a cellába kerül.
typedef TableCellValue = ({String value, bool isApproximate, String? suffix});

/// A [row] sor [column] oszlopának szövege, vagy `null` az üres cellára.
///
/// A név és a helyezések saját cellát kapnak, ezekre `null` jön. A
/// [nextDayMark] a másnapi befutás jele („+1").
TableCellValue? tableCellValueOf(
  RaceTableRow row,
  RaceTableColumn column, {
  required String nextDayMark,
}) {
  final isApproximate = row.areStatsApproximate;
  return switch (column) {
    RaceTableColumn.date => _exact(formatTableDate(row.day)),
    RaceTableColumn.name ||
    RaceTableColumn.classPlace ||
    RaceTableColumn.overallPlace ||
    RaceTableColumn.monohullPlace => null,
    RaceTableColumn.ysNumber => _map(row.ysNumberHundredths, formatYsNumber),
    RaceTableColumn.start => _instant(row.start),
    RaceTableColumn.finish => switch (row.finish) {
      final TableInstant finish => (
        value: formatTableClock(finish.instant),
        isApproximate: finish.isApproximate,
        suffix: row.isFinishNextDay ? nextDayMark : null,
      ),
      null => null,
    },
    RaceTableColumn.elapsed => switch (row.elapsed) {
      final TableDuration elapsed => (
        value: formatElapsed(elapsed.value),
        isApproximate: elapsed.isApproximate,
        suffix: null,
      ),
      null => null,
    },
    RaceTableColumn.distance => _stat(
      row.distanceMeters,
      formatTableKilometers,
      isApproximate,
    ),
    RaceTableColumn.avgSpeed => _knots(row.avgSpeedMps, isApproximate),
    RaceTableColumn.maxSpeed => _knots(row.maxSpeedMps, isApproximate),
    RaceTableColumn.avgWind => _knots(row.avgWindMps, isApproximate),
    RaceTableColumn.maxWind => _knots(row.maxWindMps, isApproximate),
    RaceTableColumn.windDirection => _stat(
      row.windPoint,
      compassPointLabel,
      isApproximate,
    ),
    RaceTableColumn.prize => _map(row.prize, (prize) => prize),
  };
}

TableCellValue _exact(String value) =>
    (value: value, isApproximate: false, suffix: null);

TableCellValue? _map<T extends Object>(T? value, String Function(T) format) =>
    value == null ? null : _exact(format(value));

TableCellValue? _stat<T extends Object>(
  T? value,
  String Function(T) format,
  bool isApproximate,
) => value == null
    ? null
    : (value: format(value), isApproximate: isApproximate, suffix: null);

TableCellValue? _knots(double? metersPerSecond, bool isApproximate) =>
    _stat(metersPerSecond, formatTableKnots, isApproximate);

TableCellValue? _instant(TableInstant? instant) => instant == null
    ? null
    : (
        value: formatTableClock(instant.instant),
        isApproximate: instant.isApproximate,
        suffix: null,
      );
