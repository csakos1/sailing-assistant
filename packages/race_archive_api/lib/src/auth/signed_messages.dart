import 'dart:convert';
import 'dart:typed_data';

/// A QR-belépés jóváhagyásának első sora (ADR 0051 D4).
const String loginApprovalTag = 'foretack-login-v1';

/// Az `owner` telefonjának regisztrációját aláíró üzenet első sora.
const String enrollmentTag = 'foretack-enroll-v1';

/// A csatlakozási kérelmet aláíró üzenet első sora.
const String joinRequestTag = 'foretack-join-v1';

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
/// Addendum 2 J3).
///
/// A [publicKey] (SubjectPublicKeyInfo DER) is benne van: az aláírás így
/// azt is bizonyítja, hogy a regisztráló a kulcs birtokosa.
Uint8List enrollmentMessage({
  required String origin,
  required String token,
  required Uint8List publicKey,
}) => _canonical([enrollmentTag, origin, token, base64Encode(publicKey)]);

/// A csatlakozási kérelemkor aláírt üzenet (ADR 0051 D3, Addendum 2 J3).
///
/// A [name] a `normalizeDisplayName` kimenete legyen; a kérelem a
/// belépési kéréshez ([requestId], [challenge]) és a kulcshoz
/// ([publicKey]) kötődik.
Uint8List joinRequestMessage({
  required String origin,
  required String requestId,
  required String challenge,
  required String name,
  required Uint8List publicKey,
}) => _canonical([
  joinRequestTag,
  origin,
  requestId,
  challenge,
  name,
  base64Encode(publicKey),
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
