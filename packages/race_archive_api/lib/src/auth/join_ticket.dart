import 'package:equatable/equatable.dart';

/// A csatlakozási kérelem azonosítójának hossza bájtban (128 bit).
const int joinRequestIdLength = 16;

/// A beküldött csatlakozási kérelem a telefonnak (ADR 0051 Addendum 5
/// M3): ezzel kérdezi le, hogy az `owner` döntött-e.
final class JoinTicket extends Equatable {
  /// Jegy a megadott mezőkkel.
  const JoinTicket({
    required this.joinRequestId,
    required this.statusToken,
    required this.expiresAt,
  });

  /// A kérelem azonosítója (base64url, 128 bit).
  final String joinRequestId;

  /// A lekérdező token (base64url, 256 bit); csak ez a telefon ismeri.
  final String statusToken;

  /// A kérelem lejárata (UTC).
  final DateTime expiresAt;

  @override
  List<Object?> get props => [joinRequestId, statusToken, expiresAt];

  @override
  String toString() => 'JoinTicket($joinRequestId, …, $expiresAt)';
}
