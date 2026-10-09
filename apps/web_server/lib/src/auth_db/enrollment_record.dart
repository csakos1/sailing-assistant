import 'package:equatable/equatable.dart';

/// Egy felhasznált regisztrációs token adatai (ADR 0051 D3).
final class EnrollmentRecord extends Equatable {
  /// Regisztráció a megadott mezőkkel.
  const EnrollmentRecord({
    required this.origin,
    required this.createdAt,
    required this.expiresAt,
    this.ownerName,
  });

  /// Az origó, amelyre a token szól.
  final String origin;

  /// Az első `owner` neve; `null`, ha már van `owner`.
  final String? ownerName;

  /// A kiadás ideje (UTC).
  final DateTime createdAt;

  /// A lejárat ideje (UTC).
  final DateTime expiresAt;

  @override
  List<Object?> get props => [origin, ownerName, createdAt, expiresAt];
}
