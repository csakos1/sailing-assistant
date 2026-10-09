import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';

// Kozos mintak a web tesztjeihez. A telemetrias versenyek ideje HELYI
// DateTime, hogy a naplo napja (helyi ido) a teszt gep idozonajatol
// fuggetlenul a vart nap legyen.

/// Telemetrias verseny: a rogzites [start]-tol [hours] oraig tart.
RaceSummary telemetrySummary(
  String id, {
  required DateTime start,
  int hours = 4,
  double? distanceMeters,
  double? maxSpeedMps,
  RaceResultInput? result,
}) {
  final recording = TimeWindow(
    start: start,
    end: start.add(Duration(hours: hours)),
  );
  return RaceSummary(
    id: id,
    name: 'Verseny $id',
    origin: TelemetryOrigin(recording),
    stats: RaceStats(
      window: RecordingWindow(recording),
      track: TrackStats(
        distanceMeters: distanceMeters,
        maxSpeedMps: maxSpeedMps,
      ),
    ),
    result: result == null
        ? null
        : RaceResult(
            raceId: id,
            content: result,
            updatedAt: DateTime.utc(2026, 10),
          ),
  );
}

/// Kezi verseny a [date] napon (`YYYY-MM-DD`).
RaceSummary manualSummary(
  String id, {
  required String date,
  double? distanceMeters,
  RaceResultInput? result,
}) => RaceSummary(
  id: id,
  name: 'Kezi $id',
  // A `!` biztonsagos: a tesztek letezo napot adnak at.
  origin: ManualOrigin(CalendarDate.tryParse(date)!),
  stats: RaceStats(
    window: const ManualEntry(),
    track: TrackStats(distanceMeters: distanceMeters),
  ),
  result: result == null
      ? null
      : RaceResult(
          raceId: id,
          content: result,
          updatedAt: DateTime.utc(2026, 10),
        ),
);
