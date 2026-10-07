import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/auth/account_info.dart';

/// Egy belépési kérés állapota a böngésző szemszögéből (ADR 0051
/// Addendum 1 H2, Addendum 3 K5).
enum LoginRequestState {
  /// Még senki nem olvasta be.
  pending,

  /// Egy telefon megnyitotta; ujjlenyomatra vár (17c).
  opened,

  /// Csatlakozási kérelem fut, az `owner` jóváhagyására vár (17d).
  joinPending,

  /// A böngésző belépett; a válasz a session-cookie-t is beállította.
  signedIn,

  /// Lejárt vagy elhasználódott; a web új kérést nyit.
  expired,
}

/// A böngésző lekérdezésének válasza.
final class LoginRequestStatus extends Equatable {
  /// Állapot; [account] csak `signedIn`-nél van.
  const LoginRequestStatus({required this.state, this.account});

  /// Az állapot.
  final LoginRequestState state;

  /// A belépett fiók, ha a [state] `signedIn`.
  final AccountInfo? account;

  @override
  List<Object?> get props => [state, account];
}
