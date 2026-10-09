import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/legacy/legacy_track_sample.dart';
import 'package:web_server/src/web_db/manual_race_record.dart';

// Kozos fixturak a regi track teszteihez (ADR 0050). A pozicio Balatonfured
// elott, eszak fele lepked 0,001 fokonkent: ket szomszedos minta tavolsaga
// 0,001 * pi / 180 * 6 371 000 m = 111,19 m.

const double legacyBaseLat = 46.95;
const double legacyBaseLon = 17.9;

/// Egy kezi verseny rekordja a [date] napon (`YYYY-MM-DD`).
ManualRaceRecord legacyManualRecord(
  String id, {
  String name = 'Regi verseny',
  String date = '2023-06-01',
  double? distanceMeters,
}) => ManualRaceRecord(
  id: id,
  input: ManualRaceInput(
    name: name,
    date: CalendarDate.tryParse(date)!,
    distanceMeters: distanceMeters,
  ),
  createdAt: DateTime.utc(2026, 10, 5),
  updatedAt: DateTime.utc(2026, 10, 5),
);

/// Egy eredmeny a [start]-[finish] hivatalos idokkel.
RaceResult legacyResult(String raceId, DateTime start, DateTime finish) =>
    RaceResult(
      raceId: raceId,
      content: RaceResultInput(officialStart: start, officialFinish: finish),
      updatedAt: DateTime.utc(2026, 10, 5),
    );

/// A [step]-edik minta a [start]-tol 10 mp-enkent, eszak fele lepkedve.
LegacyTrackSample legacyStepSample(
  DateTime start,
  int step, {
  double? sogMps = 3,
  double? twsMps = 5,
  double? twdDeg = 200,
  bool hasPosition = true,
}) => LegacyTrackSample(
  timestamp: start.add(Duration(seconds: legacySampleSeconds * step)),
  latDeg: hasPosition ? legacyBaseLat + step * 0.001 : null,
  lonDeg: hasPosition ? legacyBaseLon : null,
  sogMps: sogMps,
  stwMps: 2.5,
  twsMps: twsMps,
  twdDeg: twdDeg,
  polarTwsMps: twsMps,
  polarTwaDeg: -45,
);
