import 'package:drift/drift.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/epoch_millis.dart';

/// Egy új belépési esemény adatai (ADR 0051 Addendum 6 N5).
typedef NewLoginEvent = ({
  String id,
  String userId,
  String sessionId,
  LoginMethod method,
  String ip,
  String? browser,
  String? os,
  String? country,
  String? city,
  String? phoneCountry,
  bool isSuspicious,
});

/// A `login_events` tábla olvasó-írója (ADR 0051 Addendum 6 N5, N6).
class LoginEventRepository {
  /// Repository a [_database] fölött.
  LoginEventRepository(this._database);

  final AuthDatabase _database;

  /// Új esemény [now] időponttal.
  Future<void> insert(NewLoginEvent event, {required DateTime now}) async {
    await _database
        .into(_database.loginEvents)
        .insert(
          LoginEventsCompanion.insert(
            id: event.id,
            userId: event.userId,
            sessionId: Value(event.sessionId),
            method: event.method.name,
            ip: event.ip,
            browser: Value(event.browser),
            os: Value(event.os),
            country: Value(event.country),
            city: Value(event.city),
            phoneCountry: Value(event.phoneCountry),
            isSuspicious: event.isSuspicious,
            createdAtMs: toEpochMillis(now),
          ),
        );
  }

  /// A nyugtázatlan gyanús események a [since] után, a legújabb elöl;
  /// [userId]-vel csak az övéi.
  Future<List<SuspiciousLogin>> listUnacknowledgedSuspicious({
    required DateTime since,
    String? userId,
  }) async {
    final events = _database.loginEvents;
    final users = _database.users;
    var isListed =
        events.isSuspicious.equals(true) &
        events.acknowledgedAtMs.isNull() &
        events.createdAtMs.isBiggerOrEqualValue(toEpochMillis(since));
    if (userId != null) isListed = isListed & events.userId.equals(userId);
    final query =
        _database.select(events).join([
            innerJoin(users, users.id.equalsExp(events.userId)),
          ])
          ..where(isListed)
          ..orderBy([
            OrderingTerm.desc(events.createdAtMs),
            OrderingTerm.asc(events.id),
          ]);
    return [
      for (final row in await query.get())
        _toSuspicious(row.readTable(events), row.readTable(users).name),
    ];
  }

  /// Az [id] esemény fiókja, vagy `null`, ha nincs ilyen esemény.
  Future<String?> userIdOf(String id) async {
    final query = _database.select(_database.loginEvents)
      ..where((row) => row.id.equals(id));
    return (await query.getSingleOrNull())?.userId;
  }

  /// Az [id] esemény nyugtázása [now]-kor; a már nyugtázott marad.
  Future<void> acknowledge(String id, {required DateTime now}) async {
    await (_database.update(
      _database.loginEvents,
    )..where((row) => row.id.equals(id) & row.acknowledgedAtMs.isNull())).write(
      LoginEventsCompanion(acknowledgedAtMs: Value(toEpochMillis(now))),
    );
  }

  /// A [sessionId] munkamenet eseményeinek nyugtázása (kiléptetés, N6).
  Future<void> acknowledgeForSession(
    String sessionId, {
    required DateTime now,
  }) async {
    await (_database.update(_database.loginEvents)..where(
          (row) =>
              row.sessionId.equals(sessionId) & row.acknowledgedAtMs.isNull(),
        ))
        .write(
          LoginEventsCompanion(acknowledgedAtMs: Value(toEpochMillis(now))),
        );
  }

  /// A [cutoff]-nál régebbi események törlése (a takarítás, N5); a
  /// pontosan 30 napos még látszik.
  Future<void> deleteOlderThan(DateTime cutoff) async {
    await (_database.delete(_database.loginEvents)..where(
          (row) => row.createdAtMs.isSmallerThanValue(toEpochMillis(cutoff)),
        ))
        .go();
  }

  SuspiciousLogin _toSuspicious(LoginEventRow row, String userName) =>
      SuspiciousLogin(
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
        sessionId: row.sessionId,
      );
}
