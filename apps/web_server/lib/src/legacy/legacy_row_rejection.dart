import 'package:equatable/equatable.dart';
import 'package:web_server/src/legacy/legacy_row_problem.dart';

/// Egy Excel-sor, amely nem normalizálható; egyik formában sem íródik
/// (ADR 0048 Addendum 6 M2).
final class LegacyRowRejection extends Equatable {
  /// A [rowNumber]-edik sor elutasítása a [problems] hibákkal.
  const LegacyRowRejection({
    required this.rowNumber,
    required this.problems,
    this.name,
  });

  /// A sor száma az Excelben.
  final int rowNumber;

  /// A verseny neve, ha olvasható volt.
  final String? name;

  /// A sor összes hibája.
  final List<LegacyRowProblem> problems;

  @override
  List<Object?> get props => [rowNumber, name, problems];
}
