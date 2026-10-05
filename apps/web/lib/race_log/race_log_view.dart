import 'package:flutter/foundation.dart';
import 'package:foretack_web/race_log/elapsed_time.dart';
import 'package:foretack_web/race_log/log_period.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';

/// A napló stat-csíkjának összesítői (ADR 0048 Addendum 4 K4).
///
/// A `null` mindenhol „nincs adat", nem nulla, ahogy a `TrackStats`-ban.
typedef RaceLogTotals = ({
  Duration? timeOnWater,
  double? distanceMeters,
  double? maxSpeedMps,
});

/// A napló képernyőjének kész állapota: a választott időszak évei és az
/// összesítők (ADR 0048 Addendum 4 K2, K4).
@immutable
class RaceLogView {
  /// Nézet a [shownYears] évekkel.
  const RaceLogView({
    required this.availableYears,
    required this.selectedYear,
    required this.shownYears,
    required this.totals,
  });

  /// Minden év, amelyben van verseny, csökkenő sorrendben.
  final List<int> availableYears;

  /// A kiválasztott év; `null`, ha az összes év látszik.
  final int? selectedYear;

  /// A megjelenített évek: a kiválasztott, vagy mind.
  final List<LogYear> shownYears;

  /// A megjelenített versenyek összesítői.
  final RaceLogTotals totals;

  /// Igaz, ha az archívumban nincs verseny.
  bool get isEmpty => availableYears.isEmpty;

  /// Igaz, ha az összes év látszik.
  bool get isAllYears => selectedYear == null;

  /// A megjelenített versenyek száma.
  int get raceCount =>
      shownYears.fold(0, (count, year) => count + year.raceCount);
}

/// A [years] napló nézete a [period] időszakra.
///
/// Egy már nem létező választott év (pl. törölt kézi verseny után) a
/// legújabb évre esik vissza, ahogy a phone-on (ADR 0044 D34).
RaceLogView buildRaceLogView(List<LogYear> years, LogPeriod period) {
  final availableYears = [for (final year in years) year.year];
  if (years.isEmpty) {
    return RaceLogView(
      availableYears: availableYears,
      selectedYear: null,
      shownYears: const [],
      totals: _totalsOf(const []),
    );
  }

  final List<LogYear> shownYears;
  final int? selectedYear;
  switch (period) {
    case AllYears():
      shownYears = years;
      selectedYear = null;
    case ChosenYear(:final year) when availableYears.contains(year):
      shownYears = [
        for (final logYear in years)
          if (logYear.year == year) logYear,
      ];
      selectedYear = year;
    case NewestYear() || ChosenYear():
      shownYears = [years.first];
      selectedYear = years.first.year;
  }
  return RaceLogView(
    availableYears: availableYears,
    selectedYear: selectedYear,
    shownYears: shownYears,
    totals: _totalsOf(shownYears),
  );
}

RaceLogTotals _totalsOf(List<LogYear> years) {
  Duration? timeOnWater;
  double? distanceMeters;
  double? maxSpeedMps;
  for (final year in years) {
    for (final month in year.months) {
      for (final entry in month.entries) {
        final summary = entry.summary;
        // A kézi verseny hivatalos idők nélkül nem számít bele (K4).
        final elapsed = elapsedTimeOf(summary)?.value;
        if (elapsed != null) {
          timeOnWater = (timeOnWater ?? Duration.zero) + elapsed;
        }
        final distance = summary.stats.track.distanceMeters;
        if (distance != null) {
          distanceMeters = (distanceMeters ?? 0) + distance;
        }
        final maxSpeed = summary.stats.track.maxSpeedMps;
        final isRecord =
            maxSpeed != null && (maxSpeedMps == null || maxSpeed > maxSpeedMps);
        if (isRecord) maxSpeedMps = maxSpeed;
      }
    }
  }
  return (
    timeOnWater: timeOnWater,
    distanceMeters: distanceMeters,
    maxSpeedMps: maxSpeedMps,
  );
}
