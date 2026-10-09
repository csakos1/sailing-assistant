import 'package:flutter/foundation.dart';
import 'package:phone/features/web_access/data/web_account.dart';

/// Egy beküldött, még el nem döntött csatlakozási kérelem a telefonon
/// (ADR 0051 Addendum 8 V3, V9, Addendum 9 X4).
///
/// A [statusToken] titok: csak ez a telefon ismeri, és csak a kérelem
/// állapotát adja. A kérelem a [expiresAt] után a szerveren is lejár.
@immutable
class PendingJoin {
  /// Kérelem az [origin] szerveren, a [joinRequestId] azonosítóval.
  const PendingJoin({
    required this.origin,
    required this.joinRequestId,
    required this.statusToken,
    required this.expiresAt,
    required this.name,
  });

  /// A szerver kanonikus origója.
  final String origin;

  /// A kérelem azonosítója a szerveren.
  final String joinRequestId;

  /// A lekérdező token.
  final String statusToken;

  /// A kérelem lejárata (UTC).
  final DateTime expiresAt;

  /// A beküldött név.
  final String name;

  /// A szerver hostja, a felhasználónak mutatva.
  String get host => hostOfOrigin(origin);

  @override
  bool operator ==(Object other) =>
      other is PendingJoin &&
      other.origin == origin &&
      other.joinRequestId == joinRequestId &&
      other.statusToken == statusToken &&
      other.expiresAt == expiresAt &&
      other.name == name;

  @override
  int get hashCode =>
      Object.hash(origin, joinRequestId, statusToken, expiresAt, name);

  // A lekérdező token titok; ne kerüljön naplóba.
  @override
  String toString() => 'PendingJoin($origin, $joinRequestId, $expiresAt)';
}
