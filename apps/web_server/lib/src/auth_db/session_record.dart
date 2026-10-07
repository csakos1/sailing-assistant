import 'package:equatable/equatable.dart';

/// Egy webes munkamenet, ahogy a session-őr látja (ADR 0051 D5).
final class SessionRecord extends Equatable {
  /// Munkamenet a megadott mezőkkel.
  const SessionRecord({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.lastSeenAt,
  });

  /// A munkamenet azonosítója.
  final String id;

  /// A belépett fiók.
  final String userId;

  /// A belépés ideje (UTC); ehhez mérjük a 90 napos felső korlátot.
  final DateTime createdAt;

  /// Az utolsó rögzített aktivitás (UTC); ehhez mérjük a 7 nap tétlenséget.
  final DateTime lastSeenAt;

  @override
  List<Object?> get props => [id, userId, createdAt, lastSeenAt];
}
