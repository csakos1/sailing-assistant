import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A telemetriás verseny rögzítési ablaka: a `startedAt` és a `finishedAt`
/// közé esik (ADR 0048 Addendum 3 I3).
///
/// `null`, ha bármelyik hiányzik, vagy a sorrendjük fordított. Egy ilyen
/// sort a szerződés nem tud leírni.
TimeWindow? recordingWindowOf(Race race) =>
    switch ((race.startedAt, race.finishedAt)) {
      (final DateTime start, final DateTime finish)
          when !finish.isBefore(start) =>
        TimeWindow(start: start, end: finish),
      _ => null,
    };

/// Melyik ablakból kell számolni egy telemetriás verseny statisztikáját
/// (ADR 0048 D4 + Addendum 3 I4).
///
/// A hivatalos ablak, ha az eredményben mindkét idő megvan, és a befutás
/// későbbi a rajtnál; különben a teljes [recording], közelítőként.
StatsWindow expectedStatsWindow({
  required TimeWindow recording,
  RaceResultInput? result,
}) => switch (officialWindowOf(result)) {
  final TimeWindow official => OfficialWindow(official),
  null => RecordingWindow(recording),
};

/// A [result] hivatalos `[rajt, befutás]` ablaka, vagy `null`, ha
/// bármelyik idő hiányzik, vagy a befutás nem későbbi a rajtnál.
///
/// A telemetriás és a trackes kézi verseny (ADR 0050 Addendum 1 E2)
/// ugyanezzel a szabállyal dönti el, van-e hivatalos ablak.
TimeWindow? officialWindowOf(RaceResultInput? result) {
  final start = result?.officialStart;
  final finish = result?.officialFinish;
  if (start == null || finish == null || !finish.isAfter(start)) return null;
  return TimeWindow(start: start, end: finish);
}
