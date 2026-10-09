import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/record/race_result_input.dart';

/// Egy verseny tárolt eredménye (ADR 0048 D3).
///
/// A [content] a validált, normalizált bemenet; az [updatedAt]-et a szerver
/// állítja mentéskor.
final class RaceResult extends Equatable {
  /// A [raceId] versenyhez tartozó, [updatedAt]-kor mentett [content].
  const RaceResult({
    required this.raceId,
    required this.content,
    required this.updatedAt,
  });

  /// A verseny azonosítója (telemetriás vagy kézi).
  final String raceId;

  /// A helyezések, mezőnyök, idők, díj és összefoglaló.
  final RaceResultInput content;

  /// Az utolsó mentés ideje (UTC).
  final DateTime updatedAt;

  @override
  List<Object?> get props => [raceId, content, updatedAt];
}
