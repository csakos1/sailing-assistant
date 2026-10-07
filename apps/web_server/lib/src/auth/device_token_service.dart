import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/auth/auth_lifetimes.dart';
import 'package:web_server/src/auth/p256_signature_verifier.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth/stored_p256_key.dart';
import 'package:web_server/src/auth/token_digest.dart';
import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/auth_device.dart';
import 'package:web_server/src/auth_db/auth_user.dart';
import 'package:web_server/src/auth_db/challenge_repository.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/auth_db/device_token_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';

/// Egy eszköz-tokennel hitelesített telefon és a fiókja.
typedef DeviceCaller = ({AuthDevice device, AuthUser user});

const DecodeError _missingChallenge = DecodeError(
  path: r'$.challenge',
  expected: 'base64url of $secretTokenLength bytes',
);

/// Az eszköz-token: kihívás, kiadás és ellenőrzés (ADR 0051 Addendum 3
/// K2, K3).
///
/// A telefon a csendes eszközkulccsal aláírja a kihívást, és 15 percig
/// érvényes tokent kap. Minden ellenőrzésnél újra nézzük az eszközt és a
/// fiókot, így egy visszavonás vagy eltávolítás azonnal hat.
class DeviceTokenService {
  /// Szolgáltatás a szerver [origin]-jére.
  DeviceTokenService({
    required String origin,
    required UserRepository users,
    required DeviceRepository devices,
    required ChallengeRepository challenges,
    required DeviceTokenRepository tokens,
    required RandomBytes randomBytes,
    DateTime Function() now = utcNow,
  }) : _origin = origin,
       _users = users,
       _devices = devices,
       _challenges = challenges,
       _tokens = tokens,
       _randomBytes = randomBytes,
       _now = now;

  final String _origin;
  final UserRepository _users;
  final DeviceRepository _devices;
  final ChallengeRepository _challenges;
  final DeviceTokenRepository _tokens;
  final RandomBytes _randomBytes;
  final DateTime Function() _now;

  /// Új kihívás a [deviceId] eszköznek.
  Future<Result<IssuedSecret, ApiError>> issueChallenge(
    String deviceId,
  ) async {
    if (await _activeDevice(deviceId) == null) {
      return const Err(DeviceRevoked());
    }
    final challenge = _newSecret();
    final expiresAt = _now().add(deviceChallengeLifetime);
    await _challenges.insert(
      digest: digestToken(challenge),
      deviceId: deviceId,
      expiresAt: expiresAt,
    );
    return Ok(IssuedSecret(value: challenge, expiresAt: expiresAt));
  }

  /// Eszköz-token az aláírt kihívásért.
  ///
  /// A kihívás az aláírás ellenőrzése előtt elhasználódik: egy hibás
  /// aláírás után új kihívás kell, így egy kihívásra csak egy próba jut.
  Future<Result<IssuedSecret, ApiError>> issueToken(
    SignedDeviceRequest request,
  ) async {
    final challenge = request.challenge;
    if (challenge == null) {
      return const Err(MalformedRequest(_missingChallenge));
    }
    final device = await _activeDevice(request.deviceId);
    if (device == null) return const Err(DeviceRevoked());
    final now = _now();
    final isConsumed = await _challenges.consume(
      digestToken(challenge),
      deviceId: device.id,
      now: now,
    );
    if (!isConsumed) return const Err(RequestExpired());
    final isSigned = verifyP256Signature(
      publicKey: storedP256Key(device.deviceKey),
      message: deviceTokenMessage(
        origin: _origin,
        deviceId: device.id,
        challenge: challenge,
      ),
      derSignature: request.signature,
    );
    if (!isSigned) return const Err(NotAuthenticated());
    final token = _newSecret();
    final expiresAt = now.add(deviceTokenLifetime);
    await _tokens.insert(
      digest: digestToken(token),
      deviceId: device.id,
      expiresAt: expiresAt,
    );
    await _devices.markUsed(device.id, now: now);
    return Ok(IssuedSecret(value: token, expiresAt: expiresAt));
  }

  /// A [token] eszköze és fiókja.
  ///
  /// Ismeretlen vagy lejárt token: `NotAuthenticated` (az app újat kér).
  /// Visszavont eszköz vagy törölt fiók: `DeviceRevoked` (18d-5).
  Future<Result<DeviceCaller, ApiError>> callerOf(String token) async {
    final deviceId = await _tokens.deviceIdOf(digestToken(token), now: _now());
    if (deviceId == null) return const Err(NotAuthenticated());
    final device = await _activeDevice(deviceId);
    if (device == null) return const Err(DeviceRevoked());
    final user = await _users.get(device.userId);
    if (user == null) return const Err(DeviceRevoked());
    return Ok((device: device, user: user));
  }

  /// A lejárt kihívások és tokenek törlése (a szerver időnként hívja).
  Future<void> deleteExpired() async {
    final now = _now();
    await _challenges.deleteExpired(now);
    await _tokens.deleteExpired(now);
  }

  // Az eszköz, ha létezik és nincs visszavonva.
  Future<AuthDevice?> _activeDevice(String deviceId) async {
    final device = await _devices.get(deviceId);
    return device == null || device.isRevoked ? null : device;
  }

  String _newSecret() =>
      encodeBase64UrlUnpadded(_randomBytes(secretTokenLength));
}
