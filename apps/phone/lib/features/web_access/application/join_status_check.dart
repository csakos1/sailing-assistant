import 'package:phone/features/web_access/application/enrollment_flow.dart';
import 'package:phone/features/web_access/application/join_outcome.dart';
import 'package:phone/features/web_access/data/pending_join.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Egy függő csatlakozási kérelem lekérdezése és a döntés végrehajtása
/// (ADR 0051 Addendum 8 V9, Addendum 9 X3).
///
/// Jóváhagyáskor a fiók a tárba kerül (a kérelmet felülírja, X4);
/// elutasításkor vagy lejáratkor a kérelem és a két kulcs törlődik. A
/// lejáratot a telefon órája is eldönti: egy 24 óránál régebbi kérelemért
/// nem kell a szerverhez fordulni.
class JoinStatusCheck {
  /// Lekérdezés a [_clientFor] kliensekkel; a fiókot a [_saveAccount]
  /// menti, a kérelmet a [_clearPendingJoin], a kulcsokat a [_deleteKeys]
  /// törli; a [_now] az óra.
  JoinStatusCheck({
    required WebAccessClientFor clientFor,
    required Future<void> Function(WebAccount account) saveAccount,
    required Future<void> Function() clearPendingJoin,
    required DeleteWebKeys deleteKeys,
    required DateTime Function() now,
  }) : _clientFor = clientFor,
       _saveAccount = saveAccount,
       _clearPendingJoin = clearPendingJoin,
       _deleteKeys = deleteKeys,
       _now = now;

  final WebAccessClientFor _clientFor;
  final Future<void> Function(WebAccount account) _saveAccount;
  final Future<void> Function() _clearPendingJoin;
  final DeleteWebKeys _deleteKeys;
  final DateTime Function() _now;

  /// Lejárt-e a [pending] kérelem a telefon órája szerint.
  bool isExpired(PendingJoin pending) => !_now().isBefore(pending.expiresAt);

  /// A függő kérelem és a hozzá készült kulcsok eldobása.
  Future<void> discard() async {
    await _clearPendingJoin();
    await _deleteKeys();
  }

  /// A [pending] kérelem állapota, a döntés végrehajtásával.
  Future<JoinOutcome> run(PendingJoin pending) async {
    if (isExpired(pending)) {
      await discard();
      return const JoinNotApproved();
    }
    final result =
        await _clientFor(
          pending.origin,
        ).joinRequestStatus(
          pending.joinRequestId,
          statusToken: pending.statusToken,
        );
    return switch (result) {
      Ok(:final value) => await _apply(pending, value),
      Err() => const JoinCheckFailed(),
    };
  }

  Future<JoinOutcome> _apply(
    PendingJoin pending,
    JoinRequestStatus status,
  ) async {
    switch (status.state) {
      case JoinRequestState.pending:
        return const JoinStillPending();
      case JoinRequestState.notApproved:
        await discard();
        return const JoinNotApproved();
      case JoinRequestState.approved:
        final account = status.account;
        final deviceId = status.deviceId;
        // A dekóder `approved`-nál garantálja mindkettőt; nélkülük a fiók
        // nem menthető, ezért ez egy sikertelen lekérdezés.
        if (account == null || deviceId == null) {
          return const JoinCheckFailed();
        }
        final saved = WebAccount(
          origin: pending.origin,
          account: account,
          deviceId: deviceId,
        );
        await _saveAccount(saved);
        return JoinApproved(saved);
    }
  }
}
