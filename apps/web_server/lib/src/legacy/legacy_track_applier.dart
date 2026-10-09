import 'package:web_server/src/legacy/legacy_track_plan_item.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/transaction_runner.dart';

/// Mennyi track íródott és mennyi törlődött az `--apply`-ban.
typedef LegacyTrackApplyReport = ({int written, int cleared});

/// A track-import tervének végrehajtása (ADR 0050 D4 + Addendum 1 E4).
///
/// Minden tétel egy tranzakcióban íródik: a track nélküli tétel a korábbi
/// tracket törli, így a futás a teljes állapotot adja, és idempotens. A
/// statisztika a tranzakció után frissül (`refreshStats`, a
/// `LegacyTrackStatsRefresher.refreshAll`).
final class LegacyTrackApplier {
  /// Végrehajtó a [tracks] tárral.
  LegacyTrackApplier({
    required LegacyTrackRepository tracks,
    required TransactionRunner runInTransaction,
    required Future<void> Function() refreshStats,
  }) : _tracks = tracks,
       _runInTransaction = runInTransaction,
       _refreshStats = refreshStats;

  final LegacyTrackRepository _tracks;
  final TransactionRunner _runInTransaction;
  final Future<void> Function() _refreshStats;

  /// A [plan] végrehajtása.
  Future<LegacyTrackApplyReport> call(List<LegacyTrackPlanItem> plan) async {
    final report = await _runInTransaction(() => _write(plan));
    await _refreshStats();
    return report;
  }

  Future<LegacyTrackApplyReport> _write(
    List<LegacyTrackPlanItem> plan,
  ) async {
    var written = 0;
    var cleared = 0;
    for (final item in plan) {
      switch (item) {
        case PlannedLegacyTrack(:final race, :final samples):
          await _tracks.replace(race.id, samples);
          written++;
        case LegacyTrackWithoutWindow(:final race) ||
            LegacyTrackTooShort(:final race):
          await _tracks.delete(race.id);
          cleared++;
      }
    }
    return (written: written, cleared: cleared);
  }
}
