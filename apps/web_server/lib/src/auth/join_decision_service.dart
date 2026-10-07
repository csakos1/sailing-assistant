import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:uuid/uuid.dart';
import 'package:web_server/src/auth/auth_lifetimes.dart';
import 'package:web_server/src/auth/device_action_service.dart';
import 'package:web_server/src/auth/device_token_service.dart';
import 'package:web_server/src/auth/member_info_of.dart';
import 'package:web_server/src/auth/new_device_keys.dart';
import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/auth_device.dart';
import 'package:web_server/src/auth_db/auth_user.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/auth_db/join_request_phase.dart';
import 'package:web_server/src/auth_db/join_request_record.dart';
import 'package:web_server/src/auth_db/join_request_repository.dart';
import 'package:web_server/src/auth_db/login_request_repository.dart';
import 'package:web_server/src/auth_db/sqlite_error.dart';
import 'package:web_server/src/auth_db/user_repository.dart';
import 'package:web_server/src/web_db/transaction_runner.dart';

/// Az `owner` döntései a csatlakozási kérelmekről (ADR 0051 D3,
/// Addendum 1 H3, Addendum 5 M5, M6).
///
/// Csak az `owner` lát és dönt; a `crew` mindenre `NotAllowed`-ot kap. A
/// jóváhagyás ujjlenyomatos (`approveJoin`), az elutasítás nem.
class JoinDecisionService {
  /// Szolgáltatás a repository-k és a műveleti aláírás fölött.
  JoinDecisionService({
    required JoinRequestRepository joinRequests,
    required LoginRequestRepository loginRequests,
    required UserRepository users,
    required DeviceRepository devices,
    required DeviceActionService actions,
    required TransactionRunner runInTransaction,
    DateTime Function() now = utcNow,
    String Function() newId = _uuidV4,
  }) : _joinRequests = joinRequests,
       _loginRequests = loginRequests,
       _users = users,
       _devices = devices,
       _actions = actions,
       _runInTransaction = runInTransaction,
       _now = now,
       _newId = newId;

  final JoinRequestRepository _joinRequests;
  final LoginRequestRepository _loginRequests;
  final UserRepository _users;
  final DeviceRepository _devices;
  final DeviceActionService _actions;
  final TransactionRunner _runInTransaction;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Az élő, el nem döntött kérelmek, a legújabb elöl.
  Future<Result<List<PendingJoinRequest>, ApiError>> listPending(
    DeviceCaller caller,
  ) async {
    if (caller.user.role != UserRole.owner) return const Err(NotAllowed());
    final records = await _joinRequests.listPending(now: _now());
    return Ok([for (final record in records) _pendingOf(record)]);
  }

  /// A [joinRequestId] kérelem jóváhagyása az [approval] szerint; siker
  /// esetén a tag az aktív eszközeivel.
  ///
  /// A célt (kérelem, meglévő tag) az aláírás ellenőrzése előtt
  /// megkeressük: a `target` sor így csak ismert azonosítókból áll.
  Future<Result<MemberInfo, ApiError>> approve(
    DeviceCaller caller,
    String joinRequestId,
    JoinApproval approval,
  ) async {
    if (caller.user.role != UserRole.owner) return const Err(NotAllowed());
    final record = await _joinRequests.findLive(joinRequestId, now: _now());
    if (record == null || record.phase != JoinRequestPhase.pending) {
      return const Err(RequestExpired());
    }
    final memberId = approval.memberId;
    if (memberId != null && !await _isCrewMember(memberId)) {
      return const Err(NotAllowed());
    }
    final error = await _actions.verify(
      approval.action,
      device: caller.device,
      kind: DeviceAction.approveJoin,
      target: joinApprovalTarget(
        joinRequestId: record.id,
        memberId: memberId,
      ),
    );
    if (error != null) return Err(error);
    try {
      return Ok(await _runInTransaction(() => _admit(record, memberId)));
    } on _DecisionRejected catch (rejection) {
      return Err(rejection.error);
    }
  }

  /// A [joinRequestId] kérelem elutasítása; `null`, ha sikerült.
  ///
  /// A várakozó böngésző belépési kérése törlődik, így a következő
  /// lekérdezése `expired` (M1).
  Future<ApiError?> reject(DeviceCaller caller, String joinRequestId) async {
    if (caller.user.role != UserRole.owner) return const NotAllowed();
    final isRejected = await _runInTransaction(() async {
      final isDecided = await _joinRequests.reject(
        joinRequestId,
        now: _now(),
      );
      if (isDecided) await _loginRequests.deleteJoinPending(joinRequestId);
      return isDecided;
    });
    return isRejected ? null : const RequestExpired();
  }

  Future<MemberInfo> _admit(JoinRequestRecord record, String? memberId) async {
    final now = _now();
    // A tranzakción belül újra: ha az `owner` másik telefonja közben
    // döntött, ez `RequestExpired` (M6), nem foglalt kulcs.
    final current = await _joinRequests.findLive(record.id, now: now);
    if (current == null || current.phase != JoinRequestPhase.pending) {
      throw const _DecisionRejected(RequestExpired());
    }
    final member = await _memberFor(record, memberId, now);
    final keys = [record.publicKey, record.deviceKey];
    if (await _devices.isAnyKeyInUse(keys)) {
      throw const _DecisionRejected(keysInUseError);
    }
    final AuthDevice device;
    try {
      device = await _devices.insert(
        id: _newId(),
        userId: member.id,
        publicKey: record.publicKey,
        deviceKey: record.deviceKey,
        name: record.deviceName,
        model: record.model,
        now: now,
      );
    } on Object catch (error) {
      // Egyidejű regisztráció ugyanazzal a kulccsal: az egyedi index fogja
      // meg; ez is foglalt kulcs, nem szerverhiba.
      if (!isSqliteError(error)) rethrow;
      throw const _DecisionRejected(keysInUseError);
    }
    final isApproved = await _joinRequests.approve(
      record.id,
      userId: member.id,
      deviceId: device.id,
      now: now,
    );
    // Az `owner` másik telefonja közben döntött.
    if (!isApproved) throw const _DecisionRejected(RequestExpired());
    // Ha a böngésző még vár, a következő lekérdezése beváltja (M5); ha már
    // nem, ez nem hiba: a tag legközelebb csak beolvas.
    await _loginRequests.approveJoined(
      record.id,
      userId: member.id,
      deviceId: device.id,
      phoneIp: record.ip,
      now: now,
      expiresAt: now.add(loginRequestStepLifetime),
    );
    return memberInfoOf(member, await _devices.listActive());
  }

  // Új tag a kérelem nevével, vagy a meglévő `crew` tag; ezt a
  // tranzakcióban újra nézzük, mert közben eltávolíthatták.
  Future<AuthUser> _memberFor(
    JoinRequestRecord record,
    String? memberId,
    DateTime now,
  ) async {
    if (memberId == null) {
      return _users.insert(
        id: _newId(),
        name: record.name,
        role: UserRole.crew,
        now: now,
      );
    }
    final member = await _users.get(memberId);
    if (member == null || member.role != UserRole.crew) {
      throw const _DecisionRejected(NotAllowed());
    }
    return member;
  }

  Future<bool> _isCrewMember(String userId) async =>
      (await _users.get(userId))?.role == UserRole.crew;

  static PendingJoinRequest _pendingOf(JoinRequestRecord record) =>
      PendingJoinRequest(
        id: record.id,
        name: record.name,
        deviceName: record.deviceName,
        model: record.model,
        ip: record.ip,
        country: record.country,
        city: record.city,
        createdAt: record.createdAt,
        expiresAt: record.expiresAt,
      );
}

// A tranzakción belüli elutasítás: a kivétel görgeti vissza a fiókot és
// az eszközt; az `approve` alakítja `Err`-ré, kifelé nem jut.
final class _DecisionRejected implements Exception {
  const _DecisionRejected(this.error);

  final ApiError error;
}

String _uuidV4() => const Uuid().v4();
