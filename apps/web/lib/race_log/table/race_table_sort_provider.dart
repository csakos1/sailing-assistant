import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/race_log/table/race_table_column.dart';
import 'package:foretack_web/race_log/table/race_table_sort.dart';

/// A táblázat rendezése (ADR 0048 Addendum 4 K26).
///
/// Nem `autoDispose`, mint a nézet: a Lista és a Táblázat közötti váltás
/// sem felejti el.
final NotifierProvider<RaceTableSortNotifier, RaceTableSort>
raceTableSortProvider = NotifierProvider<RaceTableSortNotifier, RaceTableSort>(
  RaceTableSortNotifier.new,
);

/// A [raceTableSortProvider] állapota és művelete.
class RaceTableSortNotifier extends Notifier<RaceTableSort> {
  @override
  RaceTableSort build() => RaceTableSort.initial;

  /// A [column] fejlécének kattintása (`RaceTableSort.afterTapOn`).
  void tapColumn(RaceTableColumn column) => state = state.afterTapOn(column);
}
