import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/auth/auth_lifetimes.dart';
import 'package:web_server/src/auth/p256_signature_verifier.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth/stored_p256_key.dart';
import 'package:web_server/src/auth/token_digest.dart';
import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/auth_device.dart';
import 'package:web_server/src/auth_db/challenge_purpose.dart';
import 'package:web_server/src/auth_db/challenge_repository.dart';

/// Az ujjlenyomatos műveletek kihívása és aláírása (ADR 0051 Addendum 3
/// K2, K4, Addendum 5 M2).
///
/// A telefon eszköz-tokennel kér kihívást, és a műveletet az **aláíró**
/// kulccsal (ujjlenyomattal) írja alá. A kihívás csak arra az eszközre és
/// csak műveletre szól.
class DeviceActionService {
  /// Szolgáltatás a szerver [origin]-jére.
  DeviceActionService({
    required String origin,
    required ChallengeRepository challenges,
    required RandomBytes randomBytes,
    DateTime Function() now = utcNow,
  }) : _origin = origin,
       _challenges = challenges,
       _randomBytes = randomBytes,
       _now = now;

  final String _origin;
  final ChallengeRepository _challenges;
  final RandomBytes _randomBytes;
  final DateTime Function() _now;

  /// Új műveleti kihívás a [device] eszköznek.
  Future<IssuedSecret> issueChallenge(AuthDevice device) async {
    final challenge = encodeBase64UrlUnpadded(
      _randomBytes(secretTokenLength),
    );
    final expiresAt = _now().add(actionChallengeLifetime);
    await _challenges.insert(
      digest: digestToken(challenge),
      deviceId: device.id,
      purpose: ChallengePurpose.action,
      expiresAt: expiresAt,
    );
    return IssuedSecret(value: challenge, expiresAt: expiresAt);
  }

  /// A [device] aláírása a [kind] műveletre a [target] célra; `null`, ha
  /// érvényes, különben a hiba.
  ///
  /// A kihívás az aláírás ellenőrzése előtt elhasználódik: egy kihívásra
  /// egy próba jut. A [target]-et a hívó a már megtalált célból rakja
  /// össze, így egy kliens által küldött, többsoros azonosító ide nem jut
  /// el.
  Future<ApiError?> verify(
    SignedAction action, {
    required AuthDevice device,
    required DeviceAction kind,
    required String target,
  }) async {
    final isConsumed = await _challenges.consume(
      digestToken(action.challenge),
      deviceId: device.id,
      purpose: ChallengePurpose.action,
      now: _now(),
    );
    if (!isConsumed) return const RequestExpired();
    final isSigned = verifyP256Signature(
      publicKey: storedP256Key(device.publicKey),
      message: deviceActionMessage(
        origin: _origin,
        deviceId: device.id,
        challenge: action.challenge,
        action: kind,
        target: target,
      ),
      derSignature: action.signature,
    );
    return isSigned ? null : const NotAuthenticated();
  }
}
