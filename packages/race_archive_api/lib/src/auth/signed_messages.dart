import 'dart:convert';
import 'dart:typed_data';

/// A QR-belépés jóváhagyásának első sora (ADR 0051 D4).
const String loginApprovalTag = 'foretack-login-v1';

/// Az `owner` telefonjának regisztrációját aláíró üzenet első sora.
const String enrollmentTag = 'foretack-enroll-v1';

/// A csatlakozási kérelmet aláíró üzenet első sora.
const String joinRequestTag = 'foretack-join-v1';

/// Az eszköz-tokent kérő üzenet első sora (ADR 0051 Addendum 3 K2).
const String deviceTokenTag = 'foretack-device-v1';

/// Az ujjlenyomatos művelet üzenetének első sora (Addendum 3 K2, K4).
const String deviceActionTag = 'foretack-action-v1';

/// Az ujjlenyomatot kérő műveletek (ADR 0051 Addendum 3 K4).
///
/// A `name` kerül az aláírt üzenet `action` sorába.
enum DeviceAction {
  /// Egy csatlakozási kérelem jóváhagyása.
  approveJoin,

  /// Egy eszköz visszavonása.
  revokeDevice,

  /// Egy tag eltávolítása.
  removeUser,

  /// A tartalék-jelszó beállítása.
  setPassword,

  /// A helyreállító kódok újragenerálása.
  regenerateRecoveryCodes,
}

/// A QR-belépés jóváhagyásakor aláírt kanonikus üzenet (ADR 0051 D4).
///
/// Az aláírás az origót, a kérést, a kihívást és az eszközt is lefedi, így
/// egy aláírás nem játszható vissza más szerveren, más kérésre vagy más
/// eszköz nevében.
Uint8List loginApprovalMessage({
  required String origin,
  required String requestId,
  required String challenge,
  required String deviceId,
}) => _canonical([loginApprovalTag, origin, requestId, challenge, deviceId]);

/// Az `owner` telefonjának regisztrációjakor aláírt üzenet (ADR 0051 D3,
/// Addendum 2 J3, Addendum 3 K2).
///
/// A [publicKey] (az aláíró kulcs) és a [deviceKey] (a csendes eszközkulcs)
/// SubjectPublicKeyInfo DER-je is benne van: az aláírás így azt is
/// bizonyítja, hogy a regisztráló az aláíró kulcs birtokosa, és a két kulcs
/// összetartozik.
Uint8List enrollmentMessage({
  required String origin,
  required String token,
  required Uint8List publicKey,
  required Uint8List deviceKey,
}) => _canonical([
  enrollmentTag,
  origin,
  token,
  base64Encode(publicKey),
  base64Encode(deviceKey),
]);

/// A csatlakozási kérelemkor aláírt üzenet (ADR 0051 D3, Addendum 2 J3,
/// Addendum 3 K2).
///
/// A [name] a `normalizeDisplayName` kimenete legyen; a kérelem a
/// belépési kéréshez ([requestId], [challenge]) és a két kulcshoz
/// ([publicKey], [deviceKey]) kötődik.
Uint8List joinRequestMessage({
  required String origin,
  required String requestId,
  required String challenge,
  required String name,
  required Uint8List publicKey,
  required Uint8List deviceKey,
}) => _canonical([
  joinRequestTag,
  origin,
  requestId,
  challenge,
  name,
  base64Encode(publicKey),
  base64Encode(deviceKey),
]);

/// Az eszköz-token kérésekor az **eszközkulccsal** aláírt üzenet (ADR
/// 0051 Addendum 3 K2, K3).
Uint8List deviceTokenMessage({
  required String origin,
  required String deviceId,
  required String challenge,
}) => _canonical([deviceTokenTag, origin, deviceId, challenge]);

/// Egy ujjlenyomatos művelethez az **aláíró kulccsal** aláírt üzenet (ADR
/// 0051 Addendum 3 K2, K4). A [target] az érintett azonosító, vagy `-`.
Uint8List deviceActionMessage({
  required String origin,
  required String deviceId,
  required String challenge,
  required DeviceAction action,
  required String target,
}) => _canonical([
  deviceActionTag,
  origin,
  deviceId,
  challenge,
  action.name,
  target,
]);

// A sorok `\n`-nel elválasztva, záró sortörés nélkül, UTF-8-ban. Egy
// sortörést tartalmazó mező két sornak látszana, ezért az programozói
// hiba: a hívó előbb validál.
Uint8List _canonical(List<String> lines) {
  for (final line in lines) {
    if (line.isEmpty || line.contains('\n') || line.contains('\r')) {
      throw ArgumentError.value(line, 'line', 'empty or multi-line field');
    }
  }
  return utf8.encode(lines.join('\n'));
}
