import 'dart:convert';
import 'dart:typed_data';

final RegExp _base64UrlAlphabet = RegExp(r'^[A-Za-z0-9_-]*$');

/// A [bytes] base64url-kódolva, `=` kitöltés nélkül (RFC 4648 §5).
///
/// A QR-tartalmak és a tokenek így URL-be és QR-be is tördelés nélkül
/// kerülhetnek (ADR 0051 D3, D4).
String encodeBase64UrlUnpadded(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

/// A kitöltés nélküli base64url [text] bájtjai, vagy `null`, ha nem az.
///
/// Szigorú: csak a base64url ábécé, kitöltés nélkül, és csak a kanonikus
/// alak (a visszakódolás ugyanazt adja). Így egy tokennek pontosan egy
/// szöveges alakja van, és két különböző szöveg nem jelölheti ugyanazt.
Uint8List? decodeBase64UrlUnpadded(String text) {
  if (!_base64UrlAlphabet.hasMatch(text)) return null;
  // Egy maradék karakter 6 bitet hordozna, ami bájtot nem ad ki.
  if (text.length % 4 == 1) return null;
  final padded = text.padRight(text.length + (4 - text.length % 4) % 4, '=');
  final Uint8List bytes;
  try {
    bytes = base64Url.decode(padded);
  } on FormatException {
    return null;
  }
  return encodeBase64UrlUnpadded(bytes) == text ? bytes : null;
}
