import 'package:equatable/equatable.dart';
import 'package:web_server/src/legacy/legacy_sheet_row.dart';

/// A kinyerő kimenete: a lap fejlécei és versenysorai (ADR 0048
/// Addendum 6 M8).
final class LegacySheet extends Equatable {
  /// Lap a [columns] fejlécekkel és a [rows] sorokkal.
  const LegacySheet({required this.columns, required this.rows});

  /// A lap összes fejléce, balról jobbra; a fejléc-ellenőrzés bemenete.
  final List<String> columns;

  /// A versenysorok.
  final List<LegacySheetRow> rows;

  @override
  List<Object?> get props => [columns, rows];
}
