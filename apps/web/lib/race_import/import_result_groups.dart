import 'package:race_archive_api/race_archive_api.dart';

/// Az import eredményének csoportjai a 13i sorrendjében.
enum ImportResultKind {
  /// Az archívumban eddig nem szereplő versenyek.
  added,

  /// A már archivált, most felülírt versenyek.
  updated,

  /// A nem befejezett, ezért kihagyott versenyek.
  skipped,
}

/// Egy sor az eredmény-listában. A kihagyott versenynek nincs dátuma: a
/// szerződés nem hordozza (ADR 0048 Addendum 4 K21).
typedef ImportResultEntry = ({String name, DateTime? finishedAt});

/// Egy csoport: a fajtája és a sorai.
typedef ImportResultGroup = ({
  ImportResultKind kind,
  List<ImportResultEntry> entries,
});

/// A [report] csoportjai (13i, K21).
///
/// Az üres csoport elmarad. Az új és a frissült versenyek a befejezésük
/// szerint csökkenő sorrendben jönnek, mint a naplóban; a kihagyottak a
/// szerver sorrendjében.
List<ImportResultGroup> importResultGroupsOf(ImportReport report) {
  final groups = <ImportResultGroup>[
    (kind: ImportResultKind.added, entries: _newestFirst(report.added)),
    (kind: ImportResultKind.updated, entries: _newestFirst(report.updated)),
    (
      kind: ImportResultKind.skipped,
      entries: [
        for (final race in report.skipped) (name: race.name, finishedAt: null),
      ],
    ),
  ];
  return [
    for (final group in groups)
      if (group.entries.isNotEmpty) group,
  ];
}

List<ImportResultEntry> _newestFirst(List<ImportedRace> races) {
  final sorted = [...races]
    ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
  return [
    for (final race in sorted) (name: race.name, finishedAt: race.finishedAt),
  ];
}
