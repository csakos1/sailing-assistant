import 'package:equatable/equatable.dart';

/// Egy kiadott, lejáró titok: kihívás vagy eszköz-token (ADR 0051
/// Addendum 3 K2, K3).
final class IssuedSecret extends Equatable {
  /// Titok a lejáratával.
  const IssuedSecret({required this.value, required this.expiresAt});

  /// A titok base64url-ben.
  final String value;

  /// A lejárat (UTC).
  final DateTime expiresAt;

  @override
  List<Object?> get props => [value, expiresAt];

  @override
  String toString() => 'IssuedSecret(…, $expiresAt)';
}
