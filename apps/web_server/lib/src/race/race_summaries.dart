import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/stats/expected_stats_window.dart';
import 'package:web_server/src/web_db/cached_race_stats.dart';
import 'package:web_server/src/web_db/manual_race_record.dart';

// A napló-sor összeállítása a két versenyfajtából (ADR 0048 D6 + Addendum
// 2 H2, Addendum 3 I6). Pure függvények: a szolgáltatások a betöltött
// adatokból hívják őket.

/// Egy telemetriás verseny napló-sora.
RaceSummary telemetrySummaryOf({
  required Race race,
  required TimeWindow recording,
  required RaceStats stats,
  RaceResult? result,
}) => RaceSummary(
  id: race.id,
  name: race.name,
  origin: TelemetryOrigin(recording),
  stats: stats,
  result: result,
);

/// Egy kézi verseny napló-sora.
///
/// A statok a régi trackből számoltak, ha a [cached] sor ablaka pontosan a
/// mostani hivatalos ablak (ADR 0050 D5 + Addendum 2 F1); különben a beírt
/// értékek. Ez utóbbinál az átlagsebesség táv ÷ hivatalos menetidő, ha
/// mindkettő megvan, és a menetidő pozitív (D2, I6).
RaceSummary manualSummaryOf(
  ManualRaceRecord record,
  RaceResult? result, {
  CachedRaceStats? cached,
}) => RaceSummary(
  id: record.id,
  name: record.input.name,
  origin: ManualOrigin(record.input.date),
  stats: _trackStatsOf(cached, result) ?? _enteredStatsOf(record.input, result),
  result: result,
);

/// Igaz, ha a kézi verseny napló-sora a régi trackből számolt statot
/// mutatja (ADR 0050 Addendum 2 F1, F2).
bool showsTrackStats(CachedRaceStats? cached, RaceResult? result) =>
    _trackStatsOf(cached, result) != null;

// Egy elavult sor (elmaradt frissítés) a beírt számokra esik vissza.
RaceStats? _trackStatsOf(CachedRaceStats? cached, RaceResult? result) {
  if (cached == null) return null;
  final official = officialWindowOf(result?.content);
  if (official == null || cached.window != OfficialWindow(official)) {
    return null;
  }
  return cached.toRaceStats();
}

RaceStats _enteredStatsOf(ManualRaceInput input, RaceResult? result) =>
    RaceStats(
      window: const ManualEntry(),
      track: TrackStats(
        distanceMeters: input.distanceMeters,
        maxSpeedMps: input.maxSpeedMps,
        avgSpeedMps: _averageSpeedMps(
          input.distanceMeters,
          result?.content.officialElapsed,
        ),
      ),
      avgWindMps: input.avgWindMps,
      maxWindMps: input.maxWindMps,
      windPoint: input.windPoint,
    );

/// A napló szerveroldali sorrendje: a legújabb elöl (I6).
///
/// A kulcs a hivatalos rajt, ha van, különben a rögzítés kezdete, illetve
/// a kézi verseny napjának dele (UTC). Egyenlő kulcsnál az azonosító dönt,
/// hogy a sorrend determinisztikus legyen.
int compareNewestFirst(RaceSummary a, RaceSummary b) {
  final byTime = _sortInstantOf(b).compareTo(_sortInstantOf(a));
  return byTime != 0 ? byTime : a.id.compareTo(b.id);
}

DateTime _sortInstantOf(RaceSummary summary) {
  final officialStart = summary.result?.content.officialStart;
  if (officialStart != null) return officialStart;
  return switch (summary.origin) {
    TelemetryOrigin(:final recording) => recording.start,
    ManualOrigin(:final date) => DateTime.utc(
      date.year,
      date.month,
      date.day,
      12,
    ),
  };
}

double? _averageSpeedMps(double? distanceMeters, Duration? elapsed) {
  if (distanceMeters == null || elapsed == null || elapsed <= Duration.zero) {
    return null;
  }
  return distanceMeters / (elapsed.inMilliseconds / 1000);
}
