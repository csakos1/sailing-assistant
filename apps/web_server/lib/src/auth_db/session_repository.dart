import 'package:drift/drift.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/epoch_millis.dart';
import 'package:web_server/src/auth_db/session_record.dart';
import 'package:web_server/src/geoip/geo_location.dart';

/// Egy új munkamenet böngésző-adatai (ADR 0051 D7).
typedef SessionOrigin = ({String ip, String? browser, String? os});

/// A `sessions` tábla olvasó-írója (ADR 0051 D5, D7).
class SessionRepository {
  /// Repository a [_database] fölött.
  SessionRepository(this._database);

  final AuthDatabase _database;

  /// Új munkamenet a [tokenDigest] hash-sel.
  Future<void> insert({
    required String id,
    required Uint8List tokenDigest,
    required String userId,
    required LoginMethod method,
    required SessionOrigin origin,
    required DateTime now,
    String? deviceId,
    GeoLocation location = unknownLocation,
  }) async {
    final nowMillis = toEpochMillis(now);
    await _database
        .into(_database.sessions)
        .insert(
          SessionsCompanion.insert(
            id: id,
            tokenDigest: tokenDigest,
            userId: userId,
            deviceId: Value(deviceId),
            method: method.name,
            ip: origin.ip,
            browser: Value(origin.browser),
            os: Value(origin.os),
            country: Value(location.country),
            city: Value(location.city),
            createdAtMs: nowMillis,
            lastSeenAtMs: nowMillis,
          ),
        );
  }

  /// A [tokenDigest] munkamenete, vagy `null`, ha nincs ilyen.
  ///
  /// A lejáratot a hívó nézi: a szabály (7 nap, 90 nap) nem a tábla dolga.
  Future<SessionRecord?> findByDigest(Uint8List tokenDigest) async {
    final query = _database.select(_database.sessions)
      ..where((row) => row.tokenDigest.equals(tokenDigest));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toRecord(row);
  }

  /// Az [id] munkamenet, vagy `null`, ha nincs ilyen.
  Future<SessionRecord?> findById(String id) async {
    final query = _database.select(_database.sessions)
      ..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toRecord(row);
  }

  /// A még élő munkamenetek a fiók nevével és a gyanús-jelzéssel, a
  /// legutóbb aktív elöl (Addendum 5 M8, Addendum 6 N6); [userId]-vel csak
  /// az övéi.
  ///
  /// Élő az, amelyik az [idleCutoff] után volt aktív és a [createdCutoff]
  /// után jött létre: a takarítás előtt lejárt sor sem látszik.
  Future<List<WebSession>> listLive({
    required DateTime idleCutoff,
    required DateTime createdCutoff,
    String? userId,
  }) async {
    final sessions = _database.sessions;
    final users = _database.users;
    final events = _database.loginEvents;
    var isVisible =
        sessions.lastSeenAtMs.isBiggerThanValue(toEpochMillis(idleCutoff)) &
        sessions.createdAtMs.isBiggerThanValue(toEpochMillis(createdCutoff));
    if (userId != null) isVisible = isVisible & sessions.userId.equals(userId);
    final query =
        _database.select(sessions).join([
            innerJoin(users, users.id.equalsExp(sessions.userId)),
            leftOuterJoin(events, events.sessionId.equalsExp(sessions.id)),
          ])
          ..where(isVisible)
          ..orderBy([
            OrderingTerm.desc(sessions.lastSeenAtMs),
            OrderingTerm.asc(sessions.id),
          ]);
    return [
      for (final row in await query.get())
        _toWebSession(
          row.readTable(sessions),
          row.readTable(users).name,
          isSuspicious: row.readTableOrNull(events)?.isSuspicious ?? false,
        ),
    ];
  }

  /// A [userId] fiók összes munkamenetének azonosítója, a lejártakkal
  /// együtt (az `end_sessions` CLI, ADR 0052 D10).
  Future<List<String>> idsOfUser(String userId) async {
    final query = _database.selectOnly(_database.sessions)
      ..addColumns([_database.sessions.id])
      ..where(_database.sessions.userId.equals(userId))
      ..orderBy([OrderingTerm.asc(_database.sessions.id)]);
    return [
      for (final row in await query.get())
        // Az id a PK, és a lekérdezés kifejezetten ezt választja ki.
        row.read(_database.sessions.id)!,
    ];
  }

  /// Az [id] munkamenet törlése (kiléptetés); nem létezőnél sem hiba.
  Future<void> deleteById(String id) async {
    await (_database.delete(
      _database.sessions,
    )..where((row) => row.id.equals(id))).go();
  }

  /// A [deviceId] eszközzel jóváhagyott munkamenetek törlése (visszavonás,
  /// Addendum 5 M7).
  Future<void> deleteByDevice(String deviceId) async {
    await (_database.delete(
      _database.sessions,
    )..where((row) => row.deviceId.equals(deviceId))).go();
  }

  /// Az [id] munkamenet utolsó aktivitása [now].
  Future<void> touch(String id, {required DateTime now}) async {
    await (_database.update(_database.sessions)
          ..where((row) => row.id.equals(id)))
        .write(SessionsCompanion(lastSeenAtMs: Value(toEpochMillis(now))));
  }

  /// A [tokenDigest] munkamenet törlése (kijelentkezés, lejárat).
  Future<void> deleteByDigest(Uint8List tokenDigest) async {
    await (_database.delete(
      _database.sessions,
    )..where((row) => row.tokenDigest.equals(tokenDigest))).go();
  }

  /// Az [idleCutoff]-nál régebben használt vagy a [createdCutoff]-nál
  /// régebben létrejött munkamenetek törlése.
  Future<void> deleteExpired({
    required DateTime idleCutoff,
    required DateTime createdCutoff,
  }) async {
    await (_database.delete(_database.sessions)..where(
          (row) =>
              row.lastSeenAtMs.isSmallerOrEqualValue(
                toEpochMillis(idleCutoff),
              ) |
              row.createdAtMs.isSmallerOrEqualValue(
                toEpochMillis(createdCutoff),
              ),
        ))
        .go();
  }

  SessionRecord _toRecord(SessionRow row) => SessionRecord(
    id: row.id,
    userId: row.userId,
    createdAt: fromEpochMillis(row.createdAtMs),
    lastSeenAt: fromEpochMillis(row.lastSeenAtMs),
  );

  WebSession _toWebSession(
    SessionRow row,
    String userName, {
    required bool isSuspicious,
  }) => WebSession(
    id: row.id,
    userId: row.userId,
    userName: userName,
    method: LoginMethod.values.byName(row.method),
    ip: row.ip,
    browser: row.browser,
    os: row.os,
    country: row.country,
    city: row.city,
    createdAt: fromEpochMillis(row.createdAtMs),
    lastSeenAt: fromEpochMillis(row.lastSeenAtMs),
    isSuspicious: isSuspicious,
  );
}
