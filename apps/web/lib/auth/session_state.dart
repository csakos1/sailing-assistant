import 'package:flutter/foundation.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A web munkamenete (ADR 0051 Addendum 7 P2, P3).
///
/// Sealed, hogy a kapu kimerítő `switch`-csel döntse el, mit mutat. A
/// hálózati hiba nem állapot: azt az `AsyncValue.error` hordozza.
@immutable
sealed class SessionState {
  const SessionState();
}

/// Belépve a [account] fiókkal.
final class SignedIn extends SessionState {
  /// Belépett munkamenet.
  const SignedIn(this.account);

  /// A fiók a szerver szerint; a szerepe dönti el, mit mutat a web.
  final AccountInfo account;
}

/// Kijelentkezve.
final class SignedOut extends SessionState {
  /// Kijelentkezett munkamenet; az [isExpired] a lejárt belépést jelzi.
  const SignedOut({this.isExpired = false});

  /// Munka közben járt le (egy `401` miatt, P1): a belépő képernyő ezt
  /// egy halk sorral jelzi. A saját kijelentkezésnél `false`.
  final bool isExpired;
}
