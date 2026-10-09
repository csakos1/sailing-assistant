import 'package:foretack_web/race_log/table/race_table_column.dart';
import 'package:foretack_web/race_log/table/race_table_row.dart';
import 'package:foretack_web/race_log/table/race_table_sort.dart';
import 'package:foretack_web/race_log/table/sort_direction.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A [rows] a [sort] szerint (ADR 0048 Addendum 1 G2, Addendum 4 K28).
///
/// - A hiányzó érték mindig a végén áll, iránytól függetlenül. A
///   helyezés-oszlopban előbb a DNF, utána a DSQ, utána az üres.
/// - Döntetlennél a dátum dönt (csökkenő), azon belül a bemenet
///   sorrendje: a `List.sort` nem stabil, ezért az index is kulcs.
/// - A rajt és a befutás a helyi napszak szerint rendez, nem a pillanat
///   szerint: az utóbbi a dátum oszlopot ismételné meg.
List<RaceTableRow> sortRaceTableRows(
  List<RaceTableRow> rows,
  RaceTableSort sort,
) {
  final indexed =
      [
        for (final (index, row) in rows.indexed)
          (index: index, row: row, key: _keyOf(row, sort.column)),
      ]..sort((a, b) {
        final byColumn = _compareKeys(a.key, b.key, sort.direction);
        if (byColumn != 0) return byColumn;
        final byDay = b.row.day.compareTo(a.row.day);
        if (byDay != 0) return byDay;
        return a.index.compareTo(b.index);
      });
  return List.unmodifiable([for (final item in indexed) item.row]);
}

// A rendezés kulcsa. A `rank` iránytól független csoport (0: van érték,
// nagyobb: a végére kerülő hiány-fajták); a `number` vagy a `text` csak a
// 0-s csoporton belül számít.
typedef _SortKey = ({int rank, num? number, String? text});

const _SortKey _missing = (rank: 3, number: null, text: null);

_SortKey _numberKey(num? value) =>
    value == null ? _missing : (rank: 0, number: value, text: null);

_SortKey _textKey(String? value) =>
    value == null ? _missing : (rank: 0, number: null, text: value);

int _compareKeys(_SortKey a, _SortKey b, SortDirection direction) {
  final byRank = a.rank.compareTo(b.rank);
  if (byRank != 0 || a.rank != 0) return byRank;
  final aNumber = a.number;
  final bNumber = b.number;
  final aText = a.text;
  final bText = b.text;
  final ascending = aNumber != null && bNumber != null
      ? aNumber.compareTo(bNumber)
      : aText != null && bText != null
      ? aText.compareTo(bText)
      : 0;
  return direction == SortDirection.ascending ? ascending : -ascending;
}

_SortKey _keyOf(RaceTableRow row, RaceTableColumn column) => switch (column) {
  RaceTableColumn.date => _numberKey(row.day.millisecondsSinceEpoch),
  RaceTableColumn.name => _textKey(row.name.toLowerCase()),
  RaceTableColumn.classPlace => _placingKey(row.classPlace),
  RaceTableColumn.overallPlace => _placingKey(row.overallPlace),
  RaceTableColumn.monohullPlace => _placingKey(row.monohullPlace),
  RaceTableColumn.ysNumber => _numberKey(row.ysNumberHundredths),
  RaceTableColumn.start => _numberKey(_secondOfDay(row.start)),
  RaceTableColumn.finish => _numberKey(_secondOfDay(row.finish)),
  RaceTableColumn.elapsed => _numberKey(row.elapsed?.value.inSeconds),
  RaceTableColumn.distance => _numberKey(row.distanceMeters),
  RaceTableColumn.avgSpeed => _numberKey(row.avgSpeedMps),
  RaceTableColumn.maxSpeed => _numberKey(row.maxSpeedMps),
  RaceTableColumn.avgWind => _numberKey(row.avgWindMps),
  RaceTableColumn.maxWind => _numberKey(row.maxWindMps),
  RaceTableColumn.windDirection => _numberKey(row.windPoint?.index),
  RaceTableColumn.prize => _textKey(row.prize?.toLowerCase()),
};

_SortKey _placingKey(TablePlacing? placing) => switch (placing?.placing) {
  FinishPlace(:final place) => (rank: 0, number: place, text: null),
  Dnf() => (rank: 1, number: null, text: null),
  Dsq() => (rank: 2, number: null, text: null),
  null => _missing,
};

int? _secondOfDay(TableInstant? value) {
  if (value == null) return null;
  final local = value.instant.toLocal();
  return local.hour * 3600 + local.minute * 60 + local.second;
}
