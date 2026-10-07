import 'package:equatable/equatable.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy webes fiók (ADR 0051 D2). A jelszó-hash nincs benne: azt csak a
/// tartalék-belépés olvassa, külön.
final class AuthUser extends Equatable {
  /// Fiók a megadott mezőkkel.
  const AuthUser({
    required this.id,
    required this.name,
    required this.role,
    required this.createdAt,
    this.passwordSetAt,
  });

  /// A fiók UUID-je.
  final String id;

  /// A megjelenítendő név.
  final String name;

  /// A szerep.
  final UserRole role;

  /// A létrehozás ideje (UTC).
  final DateTime createdAt;

  /// Mikor állította be a jelszót (UTC); `null`, ha nincs jelszó.
  final DateTime? passwordSetAt;

  @override
  List<Object?> get props => [id, name, role, createdAt, passwordSetAt];
}
