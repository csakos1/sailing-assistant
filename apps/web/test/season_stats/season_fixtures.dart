import 'package:domain/domain.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../support/sample_summaries.dart';

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

/// Beirt (kezi) statisztika.
RaceStats enteredStats({
  double? distanceMeters,
  double? avgSpeedMps,
  double? maxSpeedMps,
  double? avgWindMps,
  double? maxWindMps,
  CompassPoint? windPoint,
}) => RaceStats(
  window: const ManualEntry(),
  track: TrackStats(
    distanceMeters: distanceMeters,
    avgSpeedMps: avgSpeedMps,
    maxSpeedMps: maxSpeedMps,
  ),
  avgWindMps: avgWindMps,
  maxWindMps: maxWindMps,
  windPoint: windPoint,
);

/// Hivatalos rajt es befutas a [start]-tol [elapsed] hosszan.
RaceResultInput officialTimes(DateTime start, Duration elapsed) =>
    RaceResultInput(officialStart: start, officialFinish: start.add(elapsed));

/// Kezi verseny a [date] napon a megadott helyezesekkel.
RaceSummary placedRace(
  String id, {
  required String date,
  Placing? classPlace,
  Placing? overallPlace,
  Placing? monohullPlace,
}) => manualSummary(
  id,
  date: date,
  result: RaceResultInput(
    classPlace: classPlace,
    overallPlace: overallPlace,
    monohullPlace: monohullPlace,
  ),
);
