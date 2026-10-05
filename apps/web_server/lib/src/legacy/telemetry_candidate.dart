import 'package:equatable/equatable.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/legacy/budapest_time.dart';

/// Az archívum egy befejezett telemetriás versenye, amelyhez egy
/// Excel-sor párosulhat (ADR 0048 Addendum 6 M1).
final class TelemetryCandidate extends Equatable {
  /// A [id] verseny a [name] névvel, a [startedAt] kezdettel.
  const TelemetryCandidate({
    required this.id,
    required this.name,
    required this.startedAt,
  });

  /// A verseny azonosítója az archívumban.
  final String id;

  /// A verseny neve a telefonon.
  final String name;

  /// A rögzítés kezdete (UTC).
  final DateTime startedAt;

  /// A rögzítés kezdetének napja Europe/Budapest időben: a párosítás
  /// kulcsa.
  CalendarDate get day => budapestDayOf(startedAt);

  @override
  List<Object?> get props => [id, name, startedAt];
}
