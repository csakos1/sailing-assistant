import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/auth/account_info_of.dart';
import 'package:web_server/src/auth/auth_lifetimes.dart';
import 'package:web_server/src/auth/constant_time.dart';
import 'package:web_server/src/auth/new_device_keys.dart';
import 'package:web_server/src/auth/p256_public_key.dart';
import 'package:web_server/src/auth/p256_signature_verifier.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth/token_digest.dart';
import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/auth_db/join_request_phase.dart';
import 'package:web_server/src/auth_db/join_request_record.dart';
import 'package:web_server/src/auth_db/join_request_repository.dart';
import 'package:web_server/src/auth_db/login_request_phase.dart';
import 'package:web_server/src/auth_db/login_request_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';
import 'package:web_server/src/web_db/transaction_runner.dart';

/// Egyszerre legfeljebb ennyi élő, el nem döntött kérelem lehet (ADR 0051
/// D3): a nyilvános QR-ral így nem tölthető tele a lista.
const int maximumPendingJoinRequests = 5;

const JoinRequestStatus _notApproved = JoinRequestStatus(
  state: JoinRequestState.notApproved,
);

/// A csatlakozási kérelem beküldése és lekérdezése a fiók nélküli
/// telefonról (ADR 0051 D3, Addendum 5 M3, M4).
///
/// Sorrend: a két kulcs alakja → az aláírás (DB nélkül) → egy
/// tranzakcióban a belépési kérés, a kulcsok egyedisége, a függő
/// kérelmek száma, az új kérelem és a belépési kérés `joinPending`-je.
/// Egy elutasítás a tranzakciót visszagörgeti, a belépési kérés nem
/// változik.
class JoinRequestService {
  /// Szolgáltatás a szerver [origin]-jére.
  JoinRequestService({
    required String origin,
    required JoinRequestRepository joinRequests,
    required LoginRequestRepository loginRequests,
    required UserRepository users,
    required DeviceRepository devices,
    required TransactionRunner runInTransaction,
    required RandomBytes randomBytes,
    DateTime Function() now = utcNow,
  }) : _origin = origin,
       _joinRequests = joinRequests,
       _loginRequests = loginRequests,
       _users = users,
       _devices = devices,
       _runInTransaction = runInTransaction,
       _randomBytes = randomBytes,
       _now = now;

  final String _origin;
  final JoinRequestRepository _joinRequests;
  final LoginRequestRepository _loginRequests;
  final UserRepository _users;
  final DeviceRepository _devices;
  final TransactionRunner _runInTransaction;
  final RandomBytes _randomBytes;
  final DateTime Function() _now;

  /// A [request] kérelem az [ip] címről; siker esetén a telefon jegye.
  Future<Result<JoinTicket, ApiError>> submit(
    JoinRequest request, {
    required String ip,
  }) async {
    final P256PublicKey publicKey;
    switch (parseNewDeviceKeys(
      publicKey: request.publicKey,
      deviceKey: request.deviceKey,
    )) {
      case Err(:final error):
        return Err(error);
      case Ok(:final value):
        publicKey = value;
    }
    final isSigned = verifyP256Signature(
      publicKey: publicKey,
      message: joinRequestMessage(
        origin: _origin,
        requestId: request.requestId,
        challenge: request.challenge,
        name: request.name,
        publicKey: request.publicKey,
        deviceKey: request.deviceKey,
      ),
      derSignature: request.signature,
    );
    if (!isSigned) return const Err(NotAuthenticated());
    try {
      return Ok(await _runInTransaction(() => _file(request, ip)));
    } on _JoinRejected catch (rejection) {
      return Err(rejection.error);
    }
  }

  /// A [joinRequestId] kérelem állapota a [statusToken] lekérdező tokennel.
  ///
  /// Ismeretlen, lejárt, elutasított kérelem vagy rossz token: mind
  /// `notApproved`, így a válaszból egy idegen semmit nem tud meg (M1, M4).
  /// A jóváhagyottat a kérelem lejáratáig akárhányszor lekérdezheti.
  Future<JoinRequestStatus> status(
    String joinRequestId, {
    required String statusToken,
  }) async {
    final record = await _joinRequests.findLive(joinRequestId, now: _now());
    if (record == null ||
        !constantTimeEquals(digestToken(statusToken), record.statusDigest)) {
      return _notApproved;
    }
    return switch (record.phase) {
      JoinRequestPhase.pending => const JoinRequestStatus(
        state: JoinRequestState.pending,
      ),
      JoinRequestPhase.rejected => _notApproved,
      JoinRequestPhase.approved => await _approvedStatus(record),
    };
  }

  Future<JoinTicket> _file(JoinRequest request, String ip) async {
    final now = _now();
    final login = await _loginRequests.findLive(request.requestId, now: now);
    final isJoinable =
        login != null &&
        (login.phase == LoginRequestPhase.pending ||
            login.phase == LoginRequestPhase.opened) &&
        constantTimeEquals(
          digestToken(request.challenge),
          digestToken(login.challenge),
        );
    if (!isJoinable) throw const _JoinRejected(RequestExpired());
    final keys = [request.publicKey, request.deviceKey];
    if (await _devices.isAnyKeyInUse(keys) ||
        await _joinRequests.isAnyKeyPending(keys, now: now)) {
      throw const _JoinRejected(keysInUseError);
    }
    final pending = await _joinRequests.listPending(now: now);
    if (pending.length >= maximumPendingJoinRequests) {
      throw _JoinRejected(TooManyAttempts(_secondsUntilFirst(pending, now)));
    }
    final id = encodeBase64UrlUnpadded(_randomBytes(joinRequestIdLength));
    final statusToken = encodeBase64UrlUnpadded(
      _randomBytes(secretTokenLength),
    );
    final expiresAt = now.add(joinRequestLifetime);
    await _joinRequests.insert(
      (
        id: id,
        statusDigest: digestToken(statusToken),
        name: request.name,
        deviceName: request.deviceName,
        model: request.model,
        publicKey: request.publicKey,
        deviceKey: request.deviceKey,
        ip: ip,
      ),
      now: now,
      expiresAt: expiresAt,
    );
    final isMarked = await _loginRequests.markJoinPending(
      request.requestId,
      joinRequestId: id,
      now: now,
      expiresAt: now.add(joinPendingLoginLifetime),
    );
    if (!isMarked) throw const _JoinRejected(RequestExpired());
    return JoinTicket(
      joinRequestId: id,
      statusToken: statusToken,
      expiresAt: expiresAt,
    );
  }

  // Egy jóváhagyott kérelem csak akkor `approved`, ha a tag és az eszköz
  // még megvan: egy azóta eltávolított tag vagy visszavont telefon
  // `notApproved`.
  Future<JoinRequestStatus> _approvedStatus(JoinRequestRecord record) async {
    final userId = record.userId;
    final deviceId = record.deviceId;
    if (userId == null || deviceId == null) return _notApproved;
    final device = await _devices.get(deviceId);
    final user = await _users.get(userId);
    if (device == null || device.isRevoked || user == null) {
      return _notApproved;
    }
    return JoinRequestStatus(
      state: JoinRequestState.approved,
      account: accountInfoOf(user),
      deviceId: deviceId,
    );
  }

  // A legkorábban lejáró függő kérelemig hátralévő idő, felfelé kerekítve,
  // legalább 1 mp: ennyi után fér be új kérelem.
  static int _secondsUntilFirst(
    List<JoinRequestRecord> pending,
    DateTime now,
  ) {
    final first = pending
        .map((request) => request.expiresAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final millis = first.difference(now).inMilliseconds;
    final seconds = (millis + 999) ~/ 1000;
    return seconds < 1 ? 1 : seconds;
  }
}

// A tranzakción belüli elutasítás: a kivétel görgeti vissza a változást;
// a `submit` alakítja `Err`-ré, kifelé nem jut.
final class _JoinRejected implements Exception {
  const _JoinRejected(this.error);

  final ApiError error;
}
