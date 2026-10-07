import 'dart:typed_data';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/auth/account_info_of.dart';
import 'package:web_server/src/auth/enrollment_service.dart';
import 'package:web_server/src/auth/fallback_backoff.dart';
import 'package:web_server/src/auth/password_hasher.dart';
import 'package:web_server/src/auth/recovery_codes.dart';
import 'package:web_server/src/auth/session_service.dart';
import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/auth_user.dart';
import 'package:web_server/src/auth_db/recovery_code_repository.dart';
import 'package:web_server/src/auth_db/session_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';

/// Egy sikeres tartalék belépés: a fiók és a session tokenje.
typedef FallbackSignIn = ({AccountInfo account, String session});

// Egy olyan „kód-hash", amely egy valódi kódé sem lehet (a valódiak 32
// bájtos HMAC-ok): a nem kód alakú szövegre is fut egy keresés.
final Uint8List _absentCodeDigest = Uint8List(1);

/// A tartalék belépés jelszóval vagy helyreállító kóddal, csak az
/// `owner`-nek (ADR 0051 D6, Addendum 3 K10, Addendum 6 N2, N3).
///
/// Minden hiba ugyanaz a `NotAuthenticated`, és minden próbálkozás
/// pontosan egy argon2id-ellenőrzést és egy kód-keresést futtat: sem a
/// válasz, sem az idő nem árulja el, van-e jelszó, kódot próbáltak-e, vagy
/// létezik-e `owner`.
class FallbackLoginService {
  /// Szolgáltatás a fiókok, a kódok és a sessionök fölött.
  FallbackLoginService({
    required UserRepository users,
    required RecoveryCodeRepository recoveryCodes,
    required RecoveryCodeDigest digestRecoveryCode,
    required PasswordHasher hasher,
    required SessionService sessions,
    required FallbackBackoff backoff,
    DateTime Function() now = utcNow,
  }) : _users = users,
       _recoveryCodes = recoveryCodes,
       _digestRecoveryCode = digestRecoveryCode,
       _hasher = hasher,
       _sessions = sessions,
       _backoff = backoff,
       _now = now {
    // A rögzített hash már most készül: az első próbálkozás így sem fut két
    // argon2id-et, az idő nem árulja el, hogy nincs jelszó (K10). Az
    // `ignore` csak a kezeletlen hibát nyeli el; a későbbi `await` látja.
    _placeholderHash.ignore();
  }

  final UserRepository _users;
  final RecoveryCodeRepository _recoveryCodes;
  final RecoveryCodeDigest _digestRecoveryCode;
  final PasswordHasher _hasher;
  final SessionService _sessions;
  final FallbackBackoff _backoff;
  final DateTime Function() _now;

  // Egy rögzített hash a jelszó nélküli esetre; egyszer készül, induláskor,
  // ugyanazzal a költséggel, mint a valódi hash-ek.
  late final Future<String> _placeholderHash = _hasher.hash(
    'foretack-placeholder-password',
  );

  /// Belépés a [secret]-tel a [browser] böngészőnek.
  ///
  /// A várakozás alatt (`TooManyAttempts`) nem fut ellenőrzés, így a helyes
  /// jelszó sem enged be.
  Future<Result<FallbackSignIn, ApiError>> signIn(
    String secret, {
    required SessionOrigin browser,
  }) async {
    final wait = _backoff.tryBegin();
    if (wait != null) return Err(TooManyAttempts(_roundUpSeconds(wait)));
    var isSuccess = false;
    final AuthUser owner;
    final bool isCode;
    try {
      final candidate = await _users.owner();
      final isPassword = await _matchesPassword(secret, candidate);
      isCode = await _consumesCode(secret, candidate);
      if (candidate == null || (!isPassword && !isCode)) {
        return const Err(NotAuthenticated());
      }
      owner = candidate;
      isSuccess = true;
    } finally {
      // Egy váratlan hiba is próbálkozásnak számít: a foglalás nem
      // maradhat nyitva.
      _backoff.end(isSuccess: isSuccess);
    }
    final session = await _sessions.start(
      userId: owner.id,
      method: isCode ? LoginMethod.recoveryCode : LoginMethod.password,
      origin: browser,
    );
    return Ok((account: accountInfoOf(owner), session: session));
  }

  // Mindig pontosan egy argon2id: a valódi hash ellen, ha van jelszó és a
  // szöveg elfogadható hosszú; különben a rögzített hash ellen.
  Future<bool> _matchesPassword(String secret, AuthUser? owner) async {
    final stored = owner == null ? null : await _users.passwordHashOf(owner.id);
    final comparable = stored != null && isAcceptablePassword(secret)
        ? stored
        : null;
    final isMatch = await _hasher.verify(
      secret,
      comparable ?? await _placeholderHash,
    );
    return comparable != null && isMatch;
  }

  // Mindig pontosan egy kód-keresés; nem kód alakú szövegre egy biztosan
  // nem létező hash-sel.
  Future<bool> _consumesCode(String secret, AuthUser? owner) async {
    final normalized = normalizeRecoveryCode(secret);
    final digest = normalized == null
        ? _absentCodeDigest
        : _digestRecoveryCode(normalized);
    final isConsumed = await _recoveryCodes.consume(
      digest,
      userId: owner?.id ?? '',
      now: _now(),
    );
    return normalized != null && owner != null && isConsumed;
  }

  static int _roundUpSeconds(Duration wait) {
    final seconds = (wait.inMilliseconds + 999) ~/ 1000;
    return seconds < 1 ? 1 : seconds;
  }
}
