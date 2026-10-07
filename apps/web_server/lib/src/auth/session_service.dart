import 'package:race_archive_api/race_archive_api.dart';
import 'package:uuid/uuid.dart';
import 'package:web_server/src/auth/auth_lifetimes.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth/token_digest.dart';
import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/auth_user.dart';
import 'package:web_server/src/auth_db/session_record.dart';
import 'package:web_server/src/auth_db/session_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';

/// A webes session kiadása, ellenőrzése és törlése (ADR 0051 D5,
/// Addendum 3 K7).
///
/// A token 256 bites véletlen; a DB csak a hash-ét látja. A session 7 nap
/// tétlenség vagy 90 nap után lejár; az aktivitás legfeljebb óránként
/// íródik, így egy oldalbetöltés nem jár DB-írással.
class SessionService {
  /// Szolgáltatás a [sessions] és a [users] fölött.
  SessionService({
    required SessionRepository sessions,
    required UserRepository users,
    required RandomBytes randomBytes,
    DateTime Function() now = utcNow,
    String Function() newId = _uuidV4,
  }) : _sessions = sessions,
       _users = users,
       _randomBytes = randomBytes,
       _now = now,
       _newId = newId;

  final SessionRepository _sessions;
  final UserRepository _users;
  final RandomBytes _randomBytes;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Új session a [userId] fióknak; a token, amely a cookie-ba kerül.
  Future<String> start({
    required String userId,
    required LoginMethod method,
    required SessionOrigin origin,
    String? deviceId,
  }) async {
    final token = encodeBase64UrlUnpadded(_randomBytes(secretTokenLength));
    await _sessions.insert(
      id: _newId(),
      tokenDigest: digestToken(token),
      userId: userId,
      deviceId: deviceId,
      method: method,
      origin: origin,
      now: _now(),
    );
    return token;
  }

  /// A [token] session fiókja, vagy `null`, ha nincs érvényes session.
  ///
  /// A lejárt session sora itt törlődik.
  Future<AuthUser?> userOf(String token) async {
    final digest = digestToken(token);
    final session = await _sessions.findByDigest(digest);
    if (session == null) return null;
    final now = _now();
    if (_isExpired(session, now)) {
      await _sessions.deleteByDigest(digest);
      return null;
    }
    if (now.difference(session.lastSeenAt) >= sessionTouchInterval) {
      await _sessions.touch(session.id, now: now);
    }
    return _users.get(session.userId);
  }

  /// A [token] session törlése (kijelentkezés); nem létezőnél sem hiba.
  Future<void> end(String token) =>
      _sessions.deleteByDigest(digestToken(token));

  /// A lejárt sessionök törlése (a szerver időnként hívja).
  Future<void> deleteExpired() {
    final now = _now();
    return _sessions.deleteExpired(
      idleCutoff: now.subtract(sessionIdleTimeout),
      createdCutoff: now.subtract(sessionMaximumLifetime),
    );
  }

  static bool _isExpired(SessionRecord session, DateTime now) =>
      now.difference(session.lastSeenAt) >= sessionIdleTimeout ||
      now.difference(session.createdAt) >= sessionMaximumLifetime;
}

String _uuidV4() => const Uuid().v4();
