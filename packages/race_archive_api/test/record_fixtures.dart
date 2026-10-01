import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

// A v2 szerzodes tesztjeinek kozos segedei es mintai (ADR 0048 Addendum 2).
// Minden idopont UTC, mert a DateTime == az isUtc flaget is osszeveti.

T unwrap<T>(Result<T, DecodeError> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('Ok-t vartunk: $error'),
};

DecodeError errorOf<T>(Result<T, DecodeError> result) => switch (result) {
  Ok() => throw StateError('Err-t vartunk, Ok jott'),
  Err(:final error) => error,
};

Object? overTheWire(Map<String, Object?> json) => jsonDecode(jsonEncode(json));

/// Egy JSON-objektum beagyazott objektuma, modositashoz.
Map<String, Object?> objectAt(Map<String, Object?> json, String key) =>
    json[key]! as Map<String, Object?>;

final DateTime officialStart = DateTime.utc(2026, 7, 26, 9);
final DateTime officialFinish = DateTime.utc(2026, 7, 26, 14, 24);

final TimeWindow recording = TimeWindow(
  start: DateTime.utc(2026, 7, 26, 8, 2, 14),
  end: DateTime.utc(2026, 7, 26, 14, 40, 51),
);

// A `!` biztonsagos: 2025-08-23 letezo nap.
final CalendarDate manualDate = CalendarDate.tryFromParts(
  year: 2025,
  month: 8,
  day: 23,
)!;

/// Teljesen kitoltott eredmeny, mindharom helyezes-fajtaval.
final RaceResultInput fullResultInput = RaceResultInput(
  classPlace: const FinishPlace(1),
  classFleetSize: 9,
  overallPlace: const FinishPlace(3),
  overallFleetSize: 24,
  monohullPlace: const Dnf(),
  monohullFleetSize: 18,
  ysNumberHundredths: 7590,
  officialStart: officialStart,
  officialFinish: officialFinish,
  prize: 'erem es vandorkupa',
  summary: 'Gyenge eszaknyugati, Tihany utan erosodott.',
);

final RaceResult storedResult = RaceResult(
  raceId: 'race-1',
  content: fullResultInput,
  updatedAt: DateTime.utc(2026, 9, 30, 18),
);

final RaceSummary telemetrySummary = RaceSummary(
  id: 'race-1',
  name: 'Horvath Boldizsar emlekverseny',
  origin: TelemetryOrigin(recording),
  stats: RaceStats(
    window: OfficialWindow(
      TimeWindow(start: officialStart, end: officialFinish),
    ),
    track: const TrackStats(
      maxSpeedMps: 4.06,
      avgSpeedMps: 1.18,
      distanceMeters: 22600,
    ),
    avgWindMps: 2.47,
    maxWindMps: 4.94,
    windPoint: CompassPoint.northWest,
  ),
  result: storedResult,
);

final RaceSummary manualSummary = RaceSummary(
  id: 'manual-1',
  name: 'IX. Lelle Kupa',
  origin: ManualOrigin(manualDate),
  stats: const RaceStats(
    window: ManualEntry(),
    track: TrackStats(maxSpeedMps: 3.55, distanceMeters: 9800),
    windPoint: CompassPoint.southEast,
  ),
);
