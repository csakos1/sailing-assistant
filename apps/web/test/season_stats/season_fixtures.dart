import 'package:domain/domain.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:race_archive_api/race_archive_api.dart';

// A szezon-statisztika tesztjeinek mintai. A sebessegek es a szelek
// m/s-ben, a tavok meterben jonnek, ahogy a szerzodesben.

/// A [summary] verseny [stats] statisztikaval, a tobbi valtozatlan.
RaceSummary withStats(RaceSummary summary, RaceStats stats) => RaceSummary(
  id: summary.id,
  name: summary.name,
  origin: summary.origin,
  stats: stats,
  result: summary.result,
);

/// A [summary] verseny naplo-bejegyzese, a naplo napjaval.
LogEntry entryOf(RaceSummary summary) =>
    LogEntry(summary: summary, day: logDayOf(summary));

/// Hivatalos ablaku statisztika (pontos ertekek).
RaceStats officialStats({
  double? distanceMeters,
  double? maxSpeedMps,
  double? avgWindMps,
  double? maxWindMps,
}) => RaceStats(
  window: OfficialWindow(
    TimeWindow(
      start: DateTime.utc(2026, 7, 26, 9),
      end: DateTime.utc(2026, 7, 26, 12),
    ),
  ),
  track: TrackStats(distanceMeters: distanceMeters, maxSpeedMps: maxSpeedMps),
  avgWindMps: avgWindMps,
  maxWindMps: maxWindMps,
);

/// Beirt (kezi) statisztika.
RaceStats enteredStats({
  double? distanceMeters,
  double? maxSpeedMps,
  double? avgWindMps,
  double? maxWindMps,
}) => RaceStats(
  window: const ManualEntry(),
  track: TrackStats(distanceMeters: distanceMeters, maxSpeedMps: maxSpeedMps),
  avgWindMps: avgWindMps,
  maxWindMps: maxWindMps,
);

/// Hivatalos rajt es befutas a [start]-tol [elapsed] hosszan.
RaceResultInput officialTimes(DateTime start, Duration elapsed) =>
    RaceResultInput(officialStart: start, officialFinish: start.add(elapsed));
