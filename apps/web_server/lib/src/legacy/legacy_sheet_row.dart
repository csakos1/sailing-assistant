import 'package:equatable/equatable.dart';
import 'package:web_server/src/legacy/legacy_cell.dart';

/// Az Excel-napló egy versenysora, a fejléc neve szerinti cellákkal
/// (ADR 0048 Addendum 6 M8).
final class LegacySheetRow extends Equatable {
  /// A [rowNumber]-edik sor a [cells] cellákkal.
  const LegacySheetRow({required this.rowNumber, required this.cells});

  /// A sor száma az Excelben (1-től), a terv és a `--match` erre hivatkozik.
  final int rowNumber;

  /// A nem üres cellák a fejléc neve szerint.
  final Map<String, LegacyCell> cells;

  @override
  List<Object?> get props => [rowNumber, cells];
}
