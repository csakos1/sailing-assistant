import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/legacy/legacy_apply_report.dart';
import 'package:web_server/src/legacy/legacy_import_plan.dart';
import 'package:web_server/src/legacy/legacy_plan_item.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/transaction_runner.dart';

/// Az Excel-import tervének végrehajtása a `web.sqlite`-on (ADR 0048 D7,
/// Addendum 6 M4, M6).
///
/// Minden írás egy tranzakcióban történik: egy félbemaradt import nem
/// hagyhat félig írt állapotot. Meglévő kézi versenyt és meglévő
/// eredményt csak a `shouldOverwrite` ír felül. Az archívumot nem írja;
/// a párosított versenyek statisztikája a tranzakció után frissül, mert a
/// hivatalos idők az ablakot megváltoztatják (I4).
final class LegacyImportApplier {
  /// Végrehajtó a webes tárakkal; a [refreshStats] a `refreshIfStale`.
  LegacyImportApplier({
    required ManualRaceRepository manualRaces,
    required RaceResultRepository results,
    required TransactionRunner runInTransaction,
    required Future<void> Function(String raceId) refreshStats,
    DateTime Function() now = DateTime.now,
  }) : _manualRaces = manualRaces,
       _results = results,
       _runInTransaction = runInTransaction,
       _refreshStats = refreshStats,
       _now = now;

  final ManualRaceRepository _manualRaces;
  final RaceResultRepository _results;
  final TransactionRunner _runInTransaction;
  final Future<void> Function(String raceId) _refreshStats;
  final DateTime Function() _now;

  /// A [plan] végrehajtása. A `--match` hibás tervét a hívó nem adhatja
  /// át (M1): az programozói hiba.
  Future<LegacyApplyReport> call(
    LegacyImportPlan plan, {
    required bool shouldOverwrite,
  }) async {
    if (plan.matchProblems.isNotEmpty) {
      throw ArgumentError.value(plan, 'plan', 'has --match problems');
    }
    final report = await _runInTransaction(
      () => _write(plan, shouldOverwrite: shouldOverwrite),
    );
    final refreshed = <String>{};
    for (final item in report.writtenResults) {
      if (refreshed.add(item.target.id)) await _refreshStats(item.target.id);
    }
    return report;
  }

  Future<LegacyApplyReport> _write(
    LegacyImportPlan plan, {
    required bool shouldOverwrite,
  }) async {
    final now = _now().toUtc();
    final builder = _ReportBuilder();
    for (final item in plan.items) {
      switch (item) {
        case PlannedResult():
          await _writeResult(
            item,
            now,
            builder,
            shouldOverwrite: shouldOverwrite,
          );
        case PlannedManualRace():
          await _writeManualRace(
            item,
            now,
            builder,
            shouldOverwrite: shouldOverwrite,
          );
        case AmbiguousRow() || RejectedRow():
          // A kétértelmű és a hibás sor nem íródik (M1, M2).
          break;
      }
    }
    return builder.build();
  }

  Future<void> _writeResult(
    PlannedResult item,
    DateTime now,
    _ReportBuilder builder, {
    required bool shouldOverwrite,
  }) async {
    if (item.result.isEmpty) {
      builder.emptyResults.add(item);
      return;
    }
    final existing = await _results.get(item.target.id);
    if (existing != null && !shouldOverwrite) {
      builder.skippedResults.add(item);
      return;
    }
    await _results.upsert(item.target.id, item.result, updatedAt: now);
    builder.writtenResults.add(item);
  }

  Future<void> _writeManualRace(
    PlannedManualRace item,
    DateTime now,
    _ReportBuilder builder, {
    required bool shouldOverwrite,
  }) async {
    final existing = await _manualRaces.get(item.id);
    if (existing == null) {
      await _manualRaces.insert(item.id, item.race.manualRace, now: now);
      builder.createdManualRaces.add(item);
    } else if (shouldOverwrite) {
      await _manualRaces.update(item.id, item.race.manualRace, now: now);
      builder.overwrittenManualRaces.add(item);
    } else {
      builder.skippedManualRaces.add(item);
      return;
    }
    await _writeManualResult(item.id, item.race.result, now);
  }

  // Csupa üres eredmény: a sor törlődik (ADR 0048 D3, mint a webes mentés).
  Future<void> _writeManualResult(
    String raceId,
    RaceResultInput result,
    DateTime now,
  ) async {
    if (result.isEmpty) {
      await _results.delete(raceId);
    } else {
      await _results.upsert(raceId, result, updatedAt: now);
    }
  }
}

final class _ReportBuilder {
  final writtenResults = <PlannedResult>[];
  final skippedResults = <PlannedResult>[];
  final emptyResults = <PlannedResult>[];
  final createdManualRaces = <PlannedManualRace>[];
  final overwrittenManualRaces = <PlannedManualRace>[];
  final skippedManualRaces = <PlannedManualRace>[];

  LegacyApplyReport build() => LegacyApplyReport(
    writtenResults: List.unmodifiable(writtenResults),
    skippedResults: List.unmodifiable(skippedResults),
    emptyResults: List.unmodifiable(emptyResults),
    createdManualRaces: List.unmodifiable(createdManualRaces),
    overwrittenManualRaces: List.unmodifiable(overwrittenManualRaces),
    skippedManualRaces: List.unmodifiable(skippedManualRaces),
  );
}
