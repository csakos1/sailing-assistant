import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Egy regisztrált telefon (ADR 0051 D3, D10).
final class AuthDevice extends Equatable {
  /// Eszköz a megadott mezőkkel.
  const AuthDevice({
    required this.id,
    required this.userId,
    required this.publicKey,
    required this.deviceKey,
    required this.name,
    required this.model,
    required this.createdAt,
    this.lastUsedAt,
    this.revokedAt,
  });

  /// Az eszköz UUID-je; az app ezt teszi az aláírt üzenetbe.
  final String id;

  /// A fiók, amelyhez tartozik.
  final String userId;

  /// Az aláíró kulcs SubjectPublicKeyInfo DER-je (ujjlenyomattal ír alá).
  final Uint8List publicKey;

  /// A csendes eszközkulcs SubjectPublicKeyInfo DER-je (az eszköz-tokenhez,
  /// Addendum 3 K1).
  final Uint8List deviceKey;

  /// A megjelenítendő név (pl. „Ákos Pixel 8”).
  final String name;

  /// A telefon típusa (pl. „Pixel 8”).
  final String model;

  /// A regisztráció ideje (UTC).
  final DateTime createdAt;

  /// Az utolsó használat ideje (UTC), ha volt.
  final DateTime? lastUsedAt;

  /// A visszavonás ideje (UTC); `null`, ha az eszköz aktív.
  final DateTime? revokedAt;

  /// Vissza van-e vonva.
  bool get isRevoked => revokedAt != null;

  @override
  List<Object?> get props => [
    id,
    userId,
    publicKey,
    deviceKey,
    name,
    model,
    createdAt,
    lastUsedAt,
    revokedAt,
  ];
}
