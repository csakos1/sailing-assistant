import 'dart:convert';
import 'dart:typed_data';

import 'package:race_archive_api/src/auth/account_info.dart';
import 'package:race_archive_api/src/auth/base64url.dart';
import 'package:race_archive_api/src/auth/display_name.dart';
import 'package:race_archive_api/src/auth/user_role.dart';
import 'package:race_archive_api/src/json/json_reader.dart';

// A hitelesítési kodekek közös mező-olvasói (ADR 0051 Addendum 4 L2). A
// csomagból nincs exportálva: csak a két auth-kodek fájl használja.

/// Egy fiók egy beágyazott objektumból.
AccountInfo readAccountInfo(JsonReader reader) => AccountInfo(
  userId: reader.nonEmptyString('userId'),
  name: reader.nonEmptyString('name'),
  role: reader.enumByName('role', UserRole.values),
);

/// Egy base64url titok a megadott bájthosszal; minden más hiba még a
/// DB-keresés előtt.
String readSecret(JsonReader reader, String key, int length) {
  final value = reader.string(key);
  if (decodeBase64UrlUnpadded(value)?.length == length) return value;
  JsonReader.failAt(reader.childPath(key), 'base64url of $length bytes');
}

/// Szabványos base64, csak a kanonikus alak: egy aláírásnak és egy
/// kulcsnak így egy szöveges alakja van.
Uint8List readBytes(JsonReader reader, String key) {
  final value = reader.nonEmptyString(key);
  try {
    final bytes = base64.decode(value);
    if (base64.encode(bytes) == value) return bytes;
  } on FormatException {
    // Lent hibaként jelezzük.
  }
  JsonReader.failAt(reader.childPath(key), 'canonical base64');
}

/// Egy megjelenítendő név a `normalizeDisplayName` szerint egységesítve.
String readDisplayName(JsonReader reader, String key) =>
    normalizeDisplayName(reader.string(key)) ??
    JsonReader.failAt(reader.childPath(key), 'display name');
