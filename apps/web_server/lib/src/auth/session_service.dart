import 'package:race_archive_api/race_archive_api.dart';
import 'package:uuid/uuid.dart';
import 'package:web_server/src/auth/auth_lifetimes.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth/token_digest.dart';
import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/auth_user.dart';
import 'package:web_server/src/auth_db/login_event_repository.dart';
import 'package:web_server/src/auth_db/session_record.dart';
import 'package:web_server/src/auth_db/session_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';
import 'package:web_server/src/geoip/geo_location.dart';
import 'package:web_server/src/web_db/transaction_runner.dart';

/// A webes session kiadása, ellenőrzése és törlése (ADR 0051 D5,
/// Addendum 3 K7).
///
/// A token 256 bites véletlen; a DB csak a hash-ét látja. A session 7 nap
/// tétlenség vagy 90 nap után lejár; az aktivitás legfeljebb óránként
/// íródik, így egy oldalbetöltés nem jár DB-írással. Minden új session
/// egy belépési eseményt is ír, a helyével és a gyanús-jelzéssel
/// (Addendum 6 N5).
class SessionService {
  /// Szolgáltatás a [sessions], a [users] és az [events] fölött.
  SessionService({
    required SessionRepository sessions,
    required UserRepository users,
    required LoginEventRepository events,
    required TransactionRunner runInTransaction,
    required RandomBytes randomBytes,
    GeoIpLookup geoIp = withoutGeoIp,
    DateTime Function() now = utcNow,
    String Function() newId = _uuidV4,
  }) : _sessions = sessions,
       _users = users,
       _events = events,
       _runInTransaction = runInTransaction,
       _geoIp = geoIp,
       _randomBytes = randomBytes,
       _now = now,
       _newId = newId;

  final SessionRepository _sessions;
  final UserRepository _users;
  final LoginEventRepository _events;
  final TransactionRunner _runInTransaction;
  final GeoIpLookup _geoIp;
  final RandomBytes _randomBytes;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Új session a [userId] fióknak; a token, amely a cookie-ba kerül.
  ///
  /// A QR-belépésnél a [phoneIp] a jóváhagyó telefon címe: ha a böngésző
  /// és a telefon országa ismert és eltér, az esemény gyanús. A tartalék
  /// belépés mindig gyanús (K9).
  Future<String> start({
    required String userId,
    required LoginMethod method,
    required SessionOrigin origin,
    String? deviceId,
    String? phoneIp,
  }) async {
    final token = encodeBase64UrlUnpadded(_randomBytes(secretTokenLength));
    final location = _geoIp(origin.ip);
    final phoneCountry = phoneIp == null ? null : _geoIp(phoneIp).country;
    final sessionId = _newId();
    final now = _now();
    await _runInTransaction(() async {
      await _sessions.insert(
        id: sessionId,
        tokenDigest: digestToken(token),
        userId: userId,
        deviceId: deviceId,
        method: method,
        origin: origin,
        now: now,
        location: location,
      );
      await _events.insert((
        id: _newId(),
        userId: userId,
        sessionId: sessionId,
        method: method,
        ip: origin.ip,
        browser: origin.browser,
        os: origin.os,
        country: location.country,
        city: location.city,
        phoneCountry: phoneCountry,
        isSuspicious: _isSuspicious(method, location.country, phoneCountry),
      ), now: now);
    });
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

  static bool _isSuspicious(
    LoginMethod method,
    String? browserCountry,
    String? phoneCountry,
  ) =>
      method != LoginMethod.qr ||
      (browserCountry != null &&
          phoneCountry != null &&
          browserCountry != phoneCountry);

  static bool _isExpired(SessionRecord session, DateTime now) =>
      now.difference(session.lastSeenAt) >= sessionIdleTimeout ||
      now.difference(session.createdAt) >= sessionMaximumLifetime;
}

String _uuidV4() => const Uuid().v4();
