import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/auth/auth_api_client_provider.dart';
import 'package:foretack_web/auth/session_state.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A web munkamenete (ADR 0051 Addendum 7 P2).
///
/// Induláskor a `GET /api/auth/me` dönti el: `200` → belépve, `401` →
/// kijelentkezve. A hálózati hiba dobott `ApiFailure`, a kapu ÚJRA-t kínál.
/// Nem `autoDispose`: a kapu egész idő alatt figyeli.
final AsyncNotifierProvider<SessionNotifier, SessionState> sessionProvider =
    AsyncNotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);

/// A belépett fiók `owner`-e (P7). Kijelentkezve és betöltés alatt `false`.
///
/// Csak azt dönti el, mit mutat a web; a biztonság a szerveren van (`403`,
/// ADR 0051 D2).
final Provider<bool> isOwnerProvider = Provider<bool>(
  (ref) => switch (ref.watch(sessionProvider).valueOrNull) {
    SignedIn(:final account) => account.role == UserRole.owner,
    _ => false,
  },
);

/// A belépett fiók azonosítója; kijelentkezve és betöltés alatt `null`.
///
/// Az archívum kliense ezt figyeli, hogy fiókváltáskor újraépüljön.
final Provider<String?> signedInUserIdProvider = Provider<String?>(
  (ref) => switch (ref.watch(sessionProvider).valueOrNull) {
    SignedIn(:final account) => account.userId,
    _ => null,
  },
);

/// A [sessionProvider] állapota és műveletei.
class SessionNotifier extends AsyncNotifier<SessionState> {
  // `FutureOr`, hogy a tesztek egy szinkron állapottal írhassák felül.
  @override
  FutureOr<SessionState> build() => _loadSession();

  Future<SessionState> _loadSession() async {
    final result = await ref.watch(authApiClientProvider).fetchAccount();
    return switch (result) {
      Ok(value: final AccountInfo account) => SignedIn(account),
      Ok() => const SignedOut(),
      Err(:final error) => throw error,
    };
  }

  /// A belépő képernyő sikeres belépése az [account] fiókkal.
  void completeSignIn(AccountInfo account) {
    state = AsyncData(SignedIn(account));
  }

  /// Egy `401` munka közben (P3): a belépés lejárt. Kijelentkezett
  /// állapotban nem csinál semmit, hogy egy késve érkező `401` ne írja
  /// felül a saját kijelentkezést.
  void expire() {
    if (state.valueOrNull is SignedIn) {
      state = const AsyncData(SignedOut(isExpired: true));
    }
  }

  /// Kijelentkezés a szerveren; `false`, ha nem sikerült.
  ///
  /// Hibánál a web belépve marad: a session-cookie `HttpOnly`, a web nem
  /// tudja törölni, így egy idegen gépen a „kijelentkezett" kép félrevezető
  /// lenne, miközben a munkamenet él.
  Future<bool> signOut() async {
    final result = await ref.read(authApiClientProvider).signOut();
    switch (result) {
      case Ok():
        state = const AsyncData(SignedOut());
        return true;
      case Err():
        return false;
    }
  }
}
