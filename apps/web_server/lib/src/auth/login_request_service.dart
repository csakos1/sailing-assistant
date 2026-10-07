import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/auth/account_info_of.dart';
import 'package:web_server/src/auth/auth_lifetimes.dart';
import 'package:web_server/src/auth/constant_time.dart';
import 'package:web_server/src/auth/p256_signature_verifier.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth/session_service.dart';
import 'package:web_server/src/auth/stored_p256_key.dart';
import 'package:web_server/src/auth/token_digest.dart';
import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/auth_db/login_request_phase.dart';
import 'package:web_server/src/auth_db/login_request_repository.dart';
import 'package:web_server/src/auth_db/session_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';
import 'package:web_server/src/geoip/geo_location.dart';

/// Egy új belépési kérés: a webnek szóló jegy és a kötő-token, amely a
/// cookie-ba kerül.
typedef OpenedLoginRequest = ({LoginRequestTicket ticket, String binding});

/// A böngésző lekérdezésének eredménye; a beváltáskor a session tokenje
/// is.
typedef LoginPollOutcome = ({LoginRequestStatus status, String? session});

const LoginPollOutcome _expired = (
  status: LoginRequestStatus(state: LoginRequestState.expired),
  session: null,
);

/// A QR-belépés teljes útja (ADR 0051 D4, Addendum 1 H2, Addendum 3 K5).
///
/// `pending` (60 mp) → `opened` (az utolsó megnyitástól 60 mp) →
/// `approved` (60 mp a beváltásra) → beváltva: a kötő-cookie-t hordozó
/// böngésző sessiont kap, a kérés sora törlődik.
class LoginRequestService {
  /// Szolgáltatás a szerver [origin]-jére.
  LoginRequestService({
    required String origin,
    required LoginRequestRepository requests,
    required UserRepository users,
    required DeviceRepository devices,
    required SessionService sessions,
    required RandomBytes randomBytes,
    GeoIpLookup geoIp = withoutGeoIp,
    DateTime Function() now = utcNow,
  }) : _origin = origin,
       _requests = requests,
       _users = users,
       _devices = devices,
       _sessions = sessions,
       _randomBytes = randomBytes,
       _geoIp = geoIp,
       _now = now;

  final String _origin;
  final LoginRequestRepository _requests;
  final UserRepository _users;
  final DeviceRepository _devices;
  final SessionService _sessions;
  final RandomBytes _randomBytes;
  final GeoIpLookup _geoIp;
  final DateTime Function() _now;

  /// Új kérés a [browser] böngészőnek.
  Future<OpenedLoginRequest> create(SessionOrigin browser) async {
    final requestId = encodeBase64UrlUnpadded(
      _randomBytes(loginRequestIdLength),
    );
    final challenge = _newSecret();
    final binding = _newSecret();
    final now = _now();
    final expiresAt = now.add(loginRequestStepLifetime);
    await _requests.insert(
      id: requestId,
      challenge: challenge,
      bindingDigest: digestToken(binding),
      browser: browser,
      now: now,
      expiresAt: expiresAt,
    );
    final qrText = encodeQrPayload(
      LoginQrPayload(
        origin: _origin,
        requestId: requestId,
        challenge: challenge,
      ),
    );
    return (
      ticket: LoginRequestTicket(
        requestId: requestId,
        qrText: qrText,
        expiresAt: expiresAt,
      ),
      binding: binding,
    );
  }

  /// Egy (eszköz-tokennel már hitelesített) telefon megnyitja a beolvasott
  /// kérést; a válasz a kérő böngésző leírása az ujjlenyomat-ablakhoz.
  ///
  /// A [challenge] a QR-ból jön: ezzel bizonyítja a telefon, hogy a QR-t
  /// látta, nem csak az azonosítót találta ki.
  Future<Result<BrowserLoginDetails, ApiError>> open(
    String requestId, {
    required String challenge,
  }) async {
    final now = _now();
    final request = await _requests.findLive(requestId, now: now);
    final isOpenable =
        request != null &&
        _isAwaitingApproval(request.phase) &&
        constantTimeEquals(
          digestToken(challenge),
          digestToken(request.challenge),
        );
    if (!isOpenable) return const Err(RequestExpired());
    final isOpened = await _requests.open(
      requestId,
      now: now,
      expiresAt: now.add(loginRequestStepLifetime),
    );
    if (!isOpened) return const Err(RequestExpired());
    // A hely az ujjlenyomat-ablak alcímébe kerül (H6, Addendum 6 N9).
    final location = _geoIp(request.browser.ip);
    return Ok(
      BrowserLoginDetails(
        ip: request.browser.ip,
        browser: request.browser.browser,
        os: request.browser.os,
        country: location.country,
        city: location.city,
      ),
    );
  }

  /// A telefon ujjlenyomattal aláírt jóváhagyása a [phoneIp] címről.
  ///
  /// `null`, ha sikerült; különben a hiba.
  Future<ApiError?> approve(
    String requestId, {
    required SignedDeviceRequest approval,
    required String phoneIp,
  }) async {
    final device = await _devices.get(approval.deviceId);
    if (device == null || device.isRevoked) return const DeviceRevoked();
    final now = _now();
    final request = await _requests.findLive(requestId, now: now);
    if (request == null || !_isAwaitingApproval(request.phase)) {
      return const RequestExpired();
    }
    final isSigned = verifyP256Signature(
      publicKey: storedP256Key(device.publicKey),
      message: loginApprovalMessage(
        origin: _origin,
        requestId: requestId,
        challenge: request.challenge,
        deviceId: device.id,
      ),
      derSignature: approval.signature,
    );
    if (!isSigned) return const NotAuthenticated();
    final isApproved = await _requests.approve(
      requestId,
      userId: device.userId,
      deviceId: device.id,
      phoneIp: phoneIp,
      now: now,
      expiresAt: now.add(loginRequestStepLifetime),
    );
    if (!isApproved) return const RequestExpired();
    await _devices.markUsed(device.id, now: now);
    return null;
  }

  /// A böngésző lekérdezése a [binding] kötő-tokennel.
  ///
  /// Ismeretlen, lejárt vagy más böngészőhöz kötött kérés: `expired`, így
  /// egy idegen böngésző semmit nem tud meg. A jóváhagyott kérést ez a
  /// hívás váltja be: a [browser] böngésző új sessiont kap.
  Future<LoginPollOutcome> poll(
    String requestId, {
    required String? binding,
    required SessionOrigin browser,
  }) async {
    if (binding == null) return _expired;
    final now = _now();
    final request = await _requests.findLive(requestId, now: now);
    if (request == null ||
        !constantTimeEquals(digestToken(binding), request.bindingDigest)) {
      return _expired;
    }
    // A jóváhagyott, de még be nem váltott kérést ez a hívás váltja be; a
    // web így a jóváhagyást nem látja külön állapotként.
    return switch (request.phase) {
      LoginRequestPhase.pending => _stateOnly(LoginRequestState.pending),
      LoginRequestPhase.opened => _stateOnly(LoginRequestState.opened),
      LoginRequestPhase.joinPending => _stateOnly(
        LoginRequestState.joinPending,
      ),
      LoginRequestPhase.approved => await _redeem(
        requestId,
        now: now,
        browser: browser,
      ),
    };
  }

  Future<LoginPollOutcome> _redeem(
    String requestId, {
    required DateTime now,
    required SessionOrigin browser,
  }) async {
    final redeemed = await _requests.redeem(requestId, now: now);
    final userId = redeemed?.userId;
    final deviceId = redeemed?.deviceId;
    if (redeemed == null || userId == null || deviceId == null) {
      return _expired;
    }
    // A jóváhagyás és a beváltás között visszavont eszköz nem adhat
    // sessiont: a visszavonás azonnal hat (K3).
    final device = await _devices.get(deviceId);
    if (device == null || device.isRevoked) return _expired;
    final user = await _users.get(userId);
    if (user == null) return _expired;
    final session = await _sessions.start(
      userId: user.id,
      method: LoginMethod.qr,
      origin: browser,
      deviceId: deviceId,
      phoneIp: redeemed.phoneIp,
    );
    return (
      status: LoginRequestStatus(
        state: LoginRequestState.signedIn,
        account: accountInfoOf(user),
      ),
      session: session,
    );
  }

  /// A lejárt kérések törlése (a szerver időnként hívja).
  Future<void> deleteExpired() => _requests.deleteExpired(_now());

  String _newSecret() =>
      encodeBase64UrlUnpadded(_randomBytes(secretTokenLength));

  // Egy `joinPending` kérés a csatlakozó telefoné: más nem nyithatja meg
  // és nem hagyhatja jóvá (Addendum 5 M5).
  static bool _isAwaitingApproval(LoginRequestPhase phase) =>
      phase == LoginRequestPhase.pending || phase == LoginRequestPhase.opened;

  static LoginPollOutcome _stateOnly(LoginRequestState state) =>
      (status: LoginRequestStatus(state: state), session: null);
}
