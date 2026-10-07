import 'package:equatable/equatable.dart';

/// Egy új belépési kérés a weboldalnak (ADR 0051 D4, Addendum 3 K5).
///
/// A kihívás csak a [qrText]-ben van; a kötő-token cookie-ban megy, a
/// törzsben nem.
final class LoginRequestTicket extends Equatable {
  /// Kérés a megadott mezőkkel.
  const LoginRequestTicket({
    required this.requestId,
    required this.qrText,
    required this.expiresAt,
  });

  /// A kérés azonosítója; ezzel kérdez a web.
  final String requestId;

  /// A `foretack-login:v1:` QR-tartalom.
  final String qrText;

  /// A lejárat (UTC); előtte a web új kérést nyit.
  final DateTime expiresAt;

  @override
  List<Object?> get props => [requestId, qrText, expiresAt];

  // A QR-szöveg a kihívást hordozza; ne kerüljön naplóba.
  @override
  String toString() => 'LoginRequestTicket($requestId, $expiresAt)';
}
