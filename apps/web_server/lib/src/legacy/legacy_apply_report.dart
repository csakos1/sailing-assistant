import 'package:equatable/equatable.dart';
import 'package:web_server/src/legacy/legacy_plan_item.dart';

/// Mit írt az `--apply` (ADR 0048 Addendum 6 M4).
final class LegacyApplyReport extends Equatable {
  /// Jelentés a tétel-listákkal.
  const LegacyApplyReport({
    this.writtenResults = const [],
    this.skippedResults = const [],
    this.emptyResults = const [],
    this.createdManualRaces = const [],
    this.overwrittenManualRaces = const [],
    this.skippedManualRaces = const [],
  });

  /// Telemetriás versenyre írt eredmények.
  final List<PlannedResult> writtenResults;

  /// Kihagyva, mert a versenynek már van eredménye (`--overwrite` nélkül).
  final List<PlannedResult> skippedResults;

  /// Kihagyva, mert az Excel-sorban nincs eredmény-adat.
  final List<PlannedResult> emptyResults;

  /// Új kézi versenyek.
  final List<PlannedManualRace> createdManualRaces;

  /// Felülírt kézi versenyek (`--overwrite`).
  final List<PlannedManualRace> overwrittenManualRaces;

  /// Kihagyva, mert a kézi verseny már létezik (`--overwrite` nélkül).
  final List<PlannedManualRace> skippedManualRaces;

  @override
  List<Object?> get props => [
    writtenResults,
    skippedResults,
    emptyResults,
    createdManualRaces,
    overwrittenManualRaces,
    skippedManualRaces,
  ];
}
