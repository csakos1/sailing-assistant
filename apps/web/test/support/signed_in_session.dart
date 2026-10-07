import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/auth/session_provider.dart';
import 'package:foretack_web/auth/session_state.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Tesztfiok a [role] szereppel.
AccountInfo testAccount(UserRole role) => AccountInfo(
  userId: 'user-${role.name}',
  name: switch (role) {
    UserRole.owner => 'Akos',
    UserRole.crew => 'Gergo',
  },
  role: role,
);

/// Belepett munkamenet a widget-tesztekhez: a kapu azonnal a navigatort
/// mutatja, a `GET /api/auth/me` nem fut.
Override signedInSession({UserRole role = UserRole.owner}) =>
    sessionProvider.overrideWith(
      () => FixedSessionNotifier(SignedIn(testAccount(role))),
    );

/// Munkamenet, amely a megadott allapotbol indul, szerver nelkul.
class FixedSessionNotifier extends SessionNotifier {
  /// Munkamenet az [_initial] allapotbol.
  FixedSessionNotifier(this._initial);

  final SessionState _initial;

  @override
  FutureOr<SessionState> build() => _initial;
}
