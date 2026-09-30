import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/annotation/race_annotation_input.dart';

/// Egy verseny tárolt eredmény-adatai (ADR 0047 D7).
///
/// A [content] a validált, normalizált bemenet; az [updatedAt]-et a szerver
/// állítja mentéskor.
final class RaceAnnotation extends Equatable {
  /// A [raceId] versenyhez tartozó, [updatedAt]-kor mentett [content].
  const RaceAnnotation({
    required this.raceId,
    required this.content,
    required this.updatedAt,
  });

  /// A verseny UUID-je.
  final String raceId;

  /// A helyezések, mezőny-méretek és az összefoglaló.
  final RaceAnnotationInput content;

  /// Az utolsó mentés ideje (UTC).
  final DateTime updatedAt;

  @override
  List<Object?> get props => [raceId, content, updatedAt];
}
