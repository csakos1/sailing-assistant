import 'dart:typed_data';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/auth/device_action_service.dart';
import 'package:web_server/src/auth/device_token_service.dart';
import 'package:web_server/src/auth/enrollment_service.dart';
import 'package:web_server/src/auth/password_hasher.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth/recovery_codes.dart';
import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/recovery_code_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';
import 'package:web_server/src/web_db/transaction_runner.dart';

const ApiError _unacceptablePassword = MalformedRequest(
  DecodeError(path: r'$.password', expected: '12 to 128 characters'),
);

/// A tartalék belépés beállításai az `owner` telefonjáról (ADR 0051 D6,
/// Addendum 1 H9, Addendum 6 N4): jelszó, a kódok újragenerálása és az
/// állapot. Mindhárom csak az `owner`-é; a két módosítás ujjlenyomatos.
class AccountSecurityService {
  /// Szolgáltatás a fiókok, a kódok és a műveleti aláírás fölött.
  AccountSecurityService({
    required UserRepository users,
    required RecoveryCodeRepository recoveryCodes,
    required RecoveryCodeDigest digestRecoveryCode,
    required PasswordHasher hasher,
    required DeviceActionService actions,
    required TransactionRunner runInTransaction,
    required RandomBytes randomBytes,
    DateTime Function() now = utcNow,
  }) : _users = users,
       _recoveryCodes = recoveryCodes,
       _digestRecoveryCode = digestRecoveryCode,
       _hasher = hasher,
       _actions = actions,
       _runInTransaction = runInTransaction,
       _randomBytes = randomBytes,
       _now = now;

  final UserRepository _users;
  final RecoveryCodeRepository _recoveryCodes;
  final RecoveryCodeDigest _digestRecoveryCode;
  final PasswordHasher _hasher;
  final DeviceActionService _actions;
  final TransactionRunner _runInTransaction;
  final RandomBytes _randomBytes;
  final DateTime Function() _now;

  /// A jelszó és a kódok állapota a 18l-hez, a kódkészlet idejével (Z12).
  Future<Result<AccountSecurity, ApiError>> security(
    DeviceCaller caller,
  ) async {
    if (caller.user.role != UserRole.owner) return const Err(NotAllowed());
    return Ok(
      AccountSecurity(
        passwordSetAt: caller.user.passwordSetAt,
        recoveryCodesLeft: await _recoveryCodes.countUnused(caller.user.id),
        recoveryCodesGeneratedAt: await _recoveryCodes.latestCreatedAt(
          caller.user.id,
        ),
      ),
    );
  }

  /// Új tartalék-jelszó; `null`, ha sikerült.
  ///
  /// A jelszó szabályát az aláírás előtt nézzük, hogy egy elutasított
  /// jelszó ne égessen el egy ujjlenyomatot.
  Future<ApiError?> setPassword(
    DeviceCaller caller,
    PasswordChange change,
  ) async {
    if (caller.user.role != UserRole.owner) return const NotAllowed();
    if (!isAcceptablePassword(change.password)) return _unacceptablePassword;
    final error = await _actions.verify(
      change.action,
      device: caller.device,
      kind: DeviceAction.setPassword,
      target: '-',
    );
    if (error != null) return error;
    final hash = await _hasher.hash(change.password);
    final isSet = await _users.setPasswordHash(
      caller.user.id,
      hash,
      now: _now(),
    );
    return isSet ? null : const DeviceRevoked();
  }

  /// Tíz új helyreállító kód; a régiek érvénytelenek.
  Future<Result<IssuedRecoveryCodes, ApiError>> regenerateRecoveryCodes(
    DeviceCaller caller,
    SignedAction action,
  ) async {
    if (caller.user.role != UserRole.owner) return const Err(NotAllowed());
    final error = await _actions.verify(
      action,
      device: caller.device,
      kind: DeviceAction.regenerateRecoveryCodes,
      target: '-',
    );
    if (error != null) return Err(error);
    final codes = generateRecoveryCodes(_randomBytes);
    final digests = [for (final code in codes) _digestOf(code)];
    await _runInTransaction(
      () => _recoveryCodes.replaceAll(caller.user.id, digests, now: _now()),
    );
    return Ok(IssuedRecoveryCodes(codes));
  }

  Uint8List _digestOf(String code) {
    // A generált kód mindig érvényes alakú, ezért az egységesítés nem
    // adhat `null`-t.
    final normalized = normalizeRecoveryCode(code)!;
    return _digestRecoveryCode(normalized);
  }
}
