import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/race_log/race_log_providers.dart';
import 'package:foretack_web/season_stats/season_stats.dart';

/// A Statisztika-képernyő állapota: betöltés, hiba, vagy a kész
/// statisztika (ADR 0049 D4, Addendum 1 P4).
///
/// A napló nézetéből származik, tehát ugyanazt a letöltött listát és
/// ugyanazt az időszakot használja, új kérés nélkül.
final Provider<AsyncValue<SeasonStats>> seasonStatsProvider =
    Provider<AsyncValue<SeasonStats>>(
      (ref) => ref.watch(raceLogViewProvider).whenData(buildSeasonStats),
    );
