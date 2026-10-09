import 'package:equatable/equatable.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy tárolt kézi verseny: az alapadatok az azonosítóval és a
/// mentési időkkel (ADR 0048 D2).
final class ManualRaceRecord extends Equatable {
  /// Kézi verseny az [id] azonosítóval.
  const ManualRaceRecord({
    required this.id,
    required this.input,
    required this.createdAt,
    required this.updatedAt,
  });

  /// A szerver által adott UUID.
  final String id;

  /// A név, a nap és a beírt statok.
  final ManualRaceInput input;

  /// A létrehozás ideje (UTC).
  final DateTime createdAt;

  /// Az utolsó mentés ideje (UTC).
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, input, createdAt, updatedAt];
}
