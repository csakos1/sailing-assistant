import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/epoch_millis.dart';
import 'package:web_server/src/auth_db/login_request_phase.dart';
import 'package:web_server/src/auth_db/login_request_record.dart';
import 'package:web_server/src/auth_db/session_repository.dart';

/// A `login_requests` tábla olvasó-írója (ADR 0051 D4, Addendum 3 K5).
///
/// Minden állapotváltás egyetlen feltételes `UPDATE`/`DELETE`: két
/// egyidejű jóváhagyásból vagy beváltásból csak az egyik sikerül.
class LoginRequestRepository {
  /// Repository a [_database] fölött.
  LoginRequestRepository(this._database);

  final AuthDatabase _database;

  /// Új, `pending` kérés.
  Future<void> insert({
    required String id,
    required String challenge,
    required Uint8List bindingDigest,
    required SessionOrigin browser,
    required DateTime now,
    required DateTime expiresAt,
  }) async {
    await _database
        .into(_database.loginRequests)
        .insert(
          LoginRequestsCompanion.insert(
            id: id,
            challenge: challenge,
            bindingDigest: bindingDigest,
            state: LoginRequestPhase.pending.name,
            ip: browser.ip,
            browser: Value(browser.browser),
            os: Value(browser.os),
            createdAtMs: toEpochMillis(now),
            expiresAtMs: toEpochMillis(expiresAt),
          ),
        );
  }

  /// Az [id] kérés, ha [now]-kor még él; különben `null`.
  Future<LoginRequestRecord?> findLive(
    String id, {
    required DateTime now,
  }) async {
    final query = _database.select(_database.loginRequests)
      ..where(
        (row) =>
            row.id.equals(id) &
            row.expiresAtMs.isBiggerThanValue(toEpochMillis(now)),
      );
    final row = await query.getSingleOrNull();
    return row == null ? null : _toRecord(row);
  }

  /// A még nem jóváhagyott, élő kérés `opened` lesz [expiresAt]
  /// lejárattal; `true`, ha sikerült.
  Future<bool> open(
    String id, {
    required DateTime now,
    required DateTime expiresAt,
  }) async {
    final updated = await _awaitingApproval(id, now).write(
      LoginRequestsCompanion(
        state: Value(LoginRequestPhase.opened.name),
        expiresAtMs: Value(toEpochMillis(expiresAt)),
      ),
    );
    return updated == 1;
  }

  /// A még nem jóváhagyott, élő kérés `approved` lesz a jóváhagyó adataival
  /// és [expiresAt] lejárattal; `true`, ha sikerült.
  Future<bool> approve(
    String id, {
    required String userId,
    required String deviceId,
    required String phoneIp,
    required DateTime now,
    required DateTime expiresAt,
  }) async {
    final updated = await _awaitingApproval(id, now).write(
      LoginRequestsCompanion(
        state: Value(LoginRequestPhase.approved.name),
        expiresAtMs: Value(toEpochMillis(expiresAt)),
        userId: Value(userId),
        deviceId: Value(deviceId),
        phoneIp: Value(phoneIp),
      ),
    );
    return updated == 1;
  }

  /// A még meg nem nyitott, élő kérés `joinPending` lesz: a [joinRequestId]
  /// kérelemre vár, [expiresAt] lejárattal (Addendum 5 M5); `true`, ha
  /// sikerült.
  Future<bool> markJoinPending(
    String id, {
    required String joinRequestId,
    required DateTime now,
    required DateTime expiresAt,
  }) async {
    // Csak még meg nem nyitott kérés (Addendum 6 N1); a szolgáltatás is
    // nézi, itt a feltételes `UPDATE` is őrzi.
    final updated =
        await (_database.update(_database.loginRequests)..where(
              (row) =>
                  row.id.equals(id) &
                  row.state.equals(LoginRequestPhase.pending.name) &
                  row.expiresAtMs.isBiggerThanValue(toEpochMillis(now)),
            ))
            .write(
              LoginRequestsCompanion(
                state: Value(LoginRequestPhase.joinPending.name),
                expiresAtMs: Value(toEpochMillis(expiresAt)),
                joinRequestId: Value(joinRequestId),
              ),
            );
    return updated == 1;
  }

  /// A [joinRequestId] kérelemre váró, élő kérés `approved` lesz a tag
  /// fiókjával és új eszközével; `false`, ha a böngésző már nem vár.
  Future<bool> approveJoined(
    String joinRequestId, {
    required String userId,
    required String deviceId,
    required String phoneIp,
    required DateTime now,
    required DateTime expiresAt,
  }) async {
    final updated =
        await (_database.update(_database.loginRequests)..where(
              (row) =>
                  row.joinRequestId.equals(joinRequestId) &
                  row.state.equals(LoginRequestPhase.joinPending.name) &
                  row.expiresAtMs.isBiggerThanValue(toEpochMillis(now)),
            ))
            .write(
              LoginRequestsCompanion(
                state: Value(LoginRequestPhase.approved.name),
                expiresAtMs: Value(toEpochMillis(expiresAt)),
                userId: Value(userId),
                deviceId: Value(deviceId),
                phoneIp: Value(phoneIp),
              ),
            );
    return updated == 1;
  }

  /// A [joinRequestId] kérelemre váró kérés törlése (elutasítás): a
  /// böngésző következő lekérdezése `expired`.
  Future<void> deleteJoinPending(String joinRequestId) async {
    await (_database.delete(_database.loginRequests)..where(
          (row) =>
              row.joinRequestId.equals(joinRequestId) &
              row.state.equals(LoginRequestPhase.joinPending.name),
        ))
        .go();
  }

  /// A jóváhagyott, élő [id] kérés beváltása: a sora törlődik, és a
  /// beváltott kérés jön vissza; `null`, ha nem volt mit beváltani.
  Future<LoginRequestRecord?> redeem(
    String id, {
    required DateTime now,
  }) async {
    final rows =
        await (_database.delete(_database.loginRequests)..where(
              (row) =>
                  row.id.equals(id) &
                  row.state.equals(LoginRequestPhase.approved.name) &
                  row.expiresAtMs.isBiggerThanValue(toEpochMillis(now)),
            ))
            .goAndReturn();
    return rows.isEmpty ? null : _toRecord(rows.single);
  }

  /// A [now]-kor már lejárt kérések törlése.
  Future<void> deleteExpired(DateTime now) async {
    await (_database.delete(_database.loginRequests)..where(
          (row) => row.expiresAtMs.isSmallerOrEqualValue(toEpochMillis(now)),
        ))
        .go();
  }

  UpdateStatement<$LoginRequestsTable, LoginRequestRow> _awaitingApproval(
    String id,
    DateTime now,
  ) => _database.update(_database.loginRequests)
    ..where(
      (row) =>
          row.id.equals(id) &
          row.state.isIn([
            LoginRequestPhase.pending.name,
            LoginRequestPhase.opened.name,
          ]) &
          row.expiresAtMs.isBiggerThanValue(toEpochMillis(now)),
    );

  LoginRequestRecord _toRecord(LoginRequestRow row) => LoginRequestRecord(
    id: row.id,
    challenge: row.challenge,
    bindingDigest: row.bindingDigest,
    phase: LoginRequestPhase.values.byName(row.state),
    browser: (ip: row.ip, browser: row.browser, os: row.os),
    expiresAt: fromEpochMillis(row.expiresAtMs),
    userId: row.userId,
    deviceId: row.deviceId,
    phoneIp: row.phoneIp,
    joinRequestId: row.joinRequestId,
  );
}
