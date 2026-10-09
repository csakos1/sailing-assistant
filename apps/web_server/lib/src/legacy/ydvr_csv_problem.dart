import 'package:equatable/equatable.dart';

/// Mi a baj egy `polar.csv`-sorral (ADR 0050 Addendum 1 E3).
enum YdvrCsvProblemKind {
  /// A cellák száma eltér a fejlécétől.
  cellCount,

  /// Az időbélyeg nem `YYYY-MM-DD HH:MM:SS` alakú, vagy nem létező nap.
  time,

  /// Egy nem üres cella nem véges szám.
  number,

  /// A szélességi vagy a hosszúsági fok a tartományán kívül esik.
  coordinate,
}

/// Egy hibás `polar.csv`-sor oka (E3). A sor kimarad, a CLI kiírja.
final class YdvrCsvRowProblem extends Equatable {
  /// Hiba a [kind] fajtából; a [column] a hibás oszlop, ha egy cellához
  /// köthető.
  const YdvrCsvRowProblem(this.kind, {this.column});

  /// A hiba fajtája.
  final YdvrCsvProblemKind kind;

  /// A hibás oszlop fejléce, vagy `null` (cellaszám).
  final String? column;

  @override
  List<Object?> get props => [kind, column];
}

/// A `polar.csv` fejlécének hibája: ezzel az import nem indul (E3).
final class YdvrCsvHeaderError extends Equatable {
  /// Hiba a hiányzó és az ismétlődő kötelező oszlopokkal.
  const YdvrCsvHeaderError({
    this.missing = const [],
    this.duplicated = const [],
  });

  /// A hiányzó kötelező oszlopok, a kötelezők sorrendjében.
  final List<String> missing;

  /// A többször szereplő kötelező oszlopok.
  final List<String> duplicated;

  @override
  List<Object?> get props => [missing, duplicated];
}
