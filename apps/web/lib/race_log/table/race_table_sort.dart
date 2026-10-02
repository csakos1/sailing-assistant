import 'package:flutter/foundation.dart';
import 'package:foretack_web/race_log/table/race_table_column.dart';
import 'package:foretack_web/race_log/table/sort_direction.dart';

/// A táblázat rendezése: oszlop és irány (ADR 0048 Addendum 1 G2,
/// Addendum 4 K26).
@immutable
class RaceTableSort {
  /// Rendezés a [column] oszlop szerint, [direction] irányban.
  const RaceTableSort({required this.column, required this.direction});

  /// Az alapállapot: dátum szerint csökkenő, a legújabb elöl.
  static const RaceTableSort initial = RaceTableSort(
    column: RaceTableColumn.date,
    direction: SortDirection.descending,
  );

  /// A rendezett oszlop.
  final RaceTableColumn column;

  /// A rendezés iránya.
  final SortDirection direction;

  /// A fejléc kattintása utáni rendezés: ugyanarra az oszlopra a fordított
  /// irány, másik oszlopra annak az első iránya (mennyiségnél csökkenő,
  /// helyezésnél és szövegnél növekvő).
  RaceTableSort afterTapOn(RaceTableColumn tapped) {
    if (tapped == column) {
      return RaceTableSort(
        column: column,
        direction: direction == SortDirection.ascending
            ? SortDirection.descending
            : SortDirection.ascending,
      );
    }
    return RaceTableSort(
      column: tapped,
      direction: tapped.isQuantity
          ? SortDirection.descending
          : SortDirection.ascending,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RaceTableSort &&
      other.column == column &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(column, direction);

  @override
  String toString() => 'RaceTableSort($column, $direction)';
}
