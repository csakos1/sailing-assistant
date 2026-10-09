import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/record/race_origin.dart';
import 'package:race_archive_api/src/record/race_result.dart';
import 'package:race_archive_api/src/record/race_stats.dart';

/// A versenynapló és a táblázat egy sora (ADR 0048 D6 + Addendum 2 H2).
final class RaceSummary extends Equatable {
  /// Napló-sor az [id] versenyhez.
  const RaceSummary({
    required this.id,
    required this.name,
    required this.origin,
    required this.stats,
    this.result,
  });

  /// A verseny azonosítója: telemetriásnál a phone UUID-je, kézinél a
  /// szerveré.
  final String id;

  /// A verseny neve.
  final String name;

  /// Telemetriás vagy kézi, a hozzá tartozó idővel.
  final RaceOrigin origin;

  /// Táv, sebesség és szél, az ablakkal együtt.
  final RaceStats stats;

  /// Az eredmény; `null`, ha még nincs rögzítve.
  final RaceResult? result;

  @override
  List<Object?> get props => [id, name, origin, stats, result];
}
