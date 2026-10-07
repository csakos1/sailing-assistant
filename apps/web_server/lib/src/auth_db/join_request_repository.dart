import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/epoch_millis.dart';
import 'package:web_server/src/auth_db/join_request_phase.dart';
import 'package:web_server/src/auth_db/join_request_record.dart';

/// Egy új csatlakozási kérelem adatai, ahogy a telefon beküldte.
typedef NewJoinRequest = ({
  String id,
  Uint8List statusDigest,
  String name,
  String deviceName,
  String model,
  Uint8List publicKey,
  Uint8List deviceKey,
  String ip,
});

/// A `join_requests` tábla olvasó-írója (ADR 0051 Addendum 5 M3, M6).
///
/// A döntés egyetlen feltételes `UPDATE`: két egyidejű döntésből (az
/// `owner` két telefonja) csak az egyik sikerül.
class JoinRequestRepository {
  /// Repository a [_database] fölött.
  JoinRequestRepository(this._database);

  final AuthDatabase _database;

  /// Új, `pending` kérelem [expiresAt] lejárattal.
  Future<void> insert(
    NewJoinRequest request, {
    required DateTime now,
    required DateTime expiresAt,
  }) async {
    await _database
        .into(_database.joinRequests)
        .insert(
          JoinRequestsCompanion.insert(
            id: request.id,
            statusDigest: request.statusDigest,
            name: request.name,
            deviceName: request.deviceName,
            model: request.model,
            publicKey: request.publicKey,
            deviceKey: request.deviceKey,
            ip: request.ip,
            createdAtMs: toEpochMillis(now),
            expiresAtMs: toEpochMillis(expiresAt),
            state: JoinRequestPhase.pending.name,
          ),
        );
  }

  /// Az [id] kérelem, ha [now]-kor még él (döntés után is); különben
  /// `null`.
  Future<JoinRequestRecord?> findLive(
    String id, {
    required DateTime now,
  }) async {
    final query = _database.select(_database.joinRequests)
      ..where(
        (row) =>
            row.id.equals(id) &
            row.expiresAtMs.isBiggerThanValue(toEpochMillis(now)),
      );
    final row = await query.getSingleOrNull();
    return row == null ? null : _toRecord(row);
  }

  /// Az élő, el nem döntött kérelmek, a legújabb elöl.
  Future<List<JoinRequestRecord>> listPending({required DateTime now}) async {
    final query = _database.select(_database.joinRequests)
      ..where((row) => _isPendingAndLive(row, now))
      ..orderBy([
        (row) => OrderingTerm.desc(row.createdAtMs),
        (row) => OrderingTerm.asc(row.id),
      ]);
    return [for (final row in await query.get()) _toRecord(row)];
  }

  /// Szerepel-e a [keys] bármelyike egy élő, el nem döntött kérelemben.
  Future<bool> isAnyKeyPending(
    List<Uint8List> keys, {
    required DateTime now,
  }) async {
    final requests = _database.joinRequests;
    final query = _database.selectOnly(requests)
      ..addColumns([requests.id])
      ..where(
        _isPendingAndLive(requests, now) &
            (requests.publicKey.isIn(keys) | requests.deviceKey.isIn(keys)),
      )
      ..limit(1);
    return (await query.get()).isNotEmpty;
  }

  /// Az élő, el nem döntött [id] kérelem jóváhagyása a [userId] fiókkal és
  /// a [deviceId] eszközzel; `true`, ha sikerült.
  Future<bool> approve(
    String id, {
    required String userId,
    required String deviceId,
    required DateTime now,
  }) => _decide(
    id,
    now,
    JoinRequestsCompanion(
      state: Value(JoinRequestPhase.approved.name),
      userId: Value(userId),
      deviceId: Value(deviceId),
    ),
  );

  /// Az élő, el nem döntött [id] kérelem elutasítása; `true`, ha sikerült.
  Future<bool> reject(String id, {required DateTime now}) => _decide(
    id,
    now,
    JoinRequestsCompanion(state: Value(JoinRequestPhase.rejected.name)),
  );

  /// A [now]-kor már lejárt kérelmek törlése (eldöntöttek is).
  Future<void> deleteExpired(DateTime now) async {
    await (_database.delete(_database.joinRequests)..where(
          (row) => row.expiresAtMs.isSmallerOrEqualValue(toEpochMillis(now)),
        ))
        .go();
  }

  Future<bool> _decide(
    String id,
    DateTime now,
    JoinRequestsCompanion decision,
  ) async {
    final updated =
        await (_database.update(_database.joinRequests)..where(
              (row) => row.id.equals(id) & _isPendingAndLive(row, now),
            ))
            .write(decision);
    return updated == 1;
  }

  Expression<bool> _isPendingAndLive($JoinRequestsTable row, DateTime now) =>
      row.state.equals(JoinRequestPhase.pending.name) &
      row.expiresAtMs.isBiggerThanValue(toEpochMillis(now));

  JoinRequestRecord _toRecord(JoinRequestRow row) => JoinRequestRecord(
    id: row.id,
    statusDigest: row.statusDigest,
    name: row.name,
    deviceName: row.deviceName,
    model: row.model,
    publicKey: row.publicKey,
    deviceKey: row.deviceKey,
    ip: row.ip,
    country: row.country,
    city: row.city,
    createdAt: fromEpochMillis(row.createdAtMs),
    expiresAt: fromEpochMillis(row.expiresAtMs),
    phase: JoinRequestPhase.values.byName(row.state),
    userId: row.userId,
    deviceId: row.deviceId,
  );
}
