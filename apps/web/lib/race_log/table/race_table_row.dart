import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:foretack_web/race_detail/detail_formatters.dart';
import 'package:foretack_web/race_log/elapsed_time.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy helyezés a saját mezőnyével, ahogy a táblázat cellája mutatja.
typedef TablePlacing = ({Placing placing, int? fleetSize});

/// Egy időpont a táblázatban; közelítő, ha a rögzítésből jön (G6).
typedef TableInstant = ({DateTime instant, bool isApproximate});

/// Egy időtartam a táblázatban; közelítő, ha a rögzítésből jön (G6).
typedef TableDuration = ElapsedTime;

/// A táblázat egy sora, cellánként kész értékkel (ADR 0048 Addendum 4
/// K27).
///
/// A `null` mindenhol üres cella: a táblázatban a hiányzó érték helyén
/// semmi nem áll (G2).
@immutable
class RaceTableRow {
  /// Sor a [summary] versenyhez; a többi mező a [raceTableRowOf] szabályai
  /// szerint számolt.
  const RaceTableRow({
    required this.summary,
    required this.day,
    required this.areStatsApproximate,
    required this.isFinishNextDay,
    this.classPlace,
    this.overallPlace,
    this.monohullPlace,
    this.ysNumberHundredths,
    this.start,
    this.finish,
    this.elapsed,
    this.distanceMeters,
    this.avgSpeedMps,
    this.maxSpeedMps,
    this.avgWindMps,
    this.maxWindMps,
    this.windPoint,
    this.prize,
  });

  /// A verseny napló-sora: az azonosítóhoz és a részletezőhöz.
  final RaceSummary summary;

  /// A verseny napja, helyi naptári nap éjfélkor (`logDayOf`).
  final DateTime day;

  /// Osztályhelyezés.
  final TablePlacing? classPlace;

  /// Abszolút helyezés.
  final TablePlacing? overallPlace;

  /// Egytestű helyezés.
  final TablePlacing? monohullPlace;

  /// A YS-szám századokban.
  final int? ysNumberHundredths;

  /// A rajt.
  final TableInstant? start;

  /// A befutás.
  final TableInstant? finish;

  /// Igaz, ha a befutás helyi napja későbbi a rajténál („+1").
  final bool isFinishNextDay;

  /// A menetidő.
  final TableDuration? elapsed;

  /// Igaz, ha a táv, a sebesség és a szél a rögzítésből számolt, nem a
  /// hivatalos ablakból (H3).
  final bool areStatsApproximate;

  /// A megtett táv méterben.
  final double? distanceMeters;

  /// Az átlagsebesség m/s-ben.
  final double? avgSpeedMps;

  /// A legnagyobb sebesség m/s-ben.
  final double? maxSpeedMps;

  /// Az átlagos szél m/s-ben.
  final double? avgWindMps;

  /// A legnagyobb szél m/s-ben.
  final double? maxWindMps;

  /// Az uralkodó szélirány.
  final CompassPoint? windPoint;

  /// A díj szövege; üres szöveg helyett `null`.
  final String? prize;

  /// A verseny neve.
  String get name => summary.name;

  /// Igaz, ha kézi verseny (KÉZI címke, G6).
  bool get isManual => summary.origin is ManualOrigin;
}

/// Az [entry] napló-bejegyzés táblázat-sora (ADR 0048 Addendum 4 K27).
///
/// A rajt, a befutás és a menetidő a hivatalos érték; ha hiányzik,
/// telemetriás versenynél a rögzítésé, közelítőként. Kézi versenynél a
/// hiányzó hivatalos idő üres cella.
RaceTableRow raceTableRowOf(LogEntry entry) {
  final summary = entry.summary;
  final content = summary.result?.content;
  final recording = switch (summary.origin) {
    TelemetryOrigin(:final recording) => recording,
    ManualOrigin() => null,
  };
  final start = _instantOf(content?.officialStart, recording?.start);
  final finish = _instantOf(content?.officialFinish, recording?.end);
  final stats = summary.stats;
  final prize = content?.prize?.trim();

  return RaceTableRow(
    summary: summary,
    day: entry.day,
    classPlace: _placingOf(content?.classPlace, content?.classFleetSize),
    overallPlace: _placingOf(content?.overallPlace, content?.overallFleetSize),
    monohullPlace: _placingOf(
      content?.monohullPlace,
      content?.monohullFleetSize,
    ),
    ysNumberHundredths: content?.ysNumberHundredths,
    start: start,
    finish: finish,
    isFinishNextDay:
        start != null &&
        finish != null &&
        isNextLocalDay(start.instant, finish.instant),
    elapsed: elapsedTimeOf(summary),
    areStatsApproximate: stats.window.isApproximate,
    distanceMeters: stats.track.distanceMeters,
    avgSpeedMps: stats.track.avgSpeedMps,
    maxSpeedMps: stats.track.maxSpeedMps,
    avgWindMps: stats.avgWindMps,
    maxWindMps: stats.maxWindMps,
    windPoint: stats.windPoint,
    prize: prize == null || prize.isEmpty ? null : prize,
  );
}

TablePlacing? _placingOf(Placing? placing, int? fleetSize) =>
    placing == null ? null : (placing: placing, fleetSize: fleetSize);

TableInstant? _instantOf(DateTime? official, DateTime? recorded) {
  if (official != null) return (instant: official, isApproximate: false);
  if (recorded != null) return (instant: recorded, isApproximate: true);
  return null;
}
