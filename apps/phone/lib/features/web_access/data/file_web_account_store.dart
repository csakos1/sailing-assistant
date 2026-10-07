import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/data/web_account_codec.dart';
import 'package:phone/features/web_access/data/web_account_store.dart';

/// A fiók-fájl neve az app privát könyvtárában (V3).
const String webAccountFileName = 'web_account.json';

/// A webes fiók egy app-privát JSON-fájlban (ADR 0051 Addendum 8 V3).
///
/// Szándékosan nem a versenyek Drift-DB-jében él: egy fiók-csere vagy egy
/// visszavont eszköz takarítása így versenyt nem érinthet. Az írás egy
/// ideiglenes fájlba megy, utána `rename` cseréli: egy félbemaradt írás
/// nem hagy fél fájlt.
class FileWebAccountStore implements WebAccountStore {
  /// Tár a [_directory] által adott könyvtárban.
  FileWebAccountStore(this._directory);

  final Future<Directory> Function() _directory;

  Future<File> get _file async =>
      File('${(await _directory()).path}/$webAccountFileName');

  @override
  Future<WebAccount?> read() async {
    final file = await _file;
    final String text;
    try {
      text = await file.readAsString();
    } on PathNotFoundException {
      return null;
    } on FileSystemException {
      // Pl. nem UTF-8 tartalom: ugyanaz, mint egy sérült JSON.
      _logUnreadable(file);
      return null;
    }
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      _logUnreadable(file);
      return null;
    }
    final account = decodeWebAccount(json);
    if (account == null) _logUnreadable(file);
    return account;
  }

  @override
  Future<void> write(WebAccount account) async {
    final file = await _file;
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode(encodeWebAccount(account)),
      flush: true,
    );
    await temporary.rename(file.path);
  }

  @override
  Future<void> delete() async {
    final file = await _file;
    for (final target in [file, File('${file.path}.tmp')]) {
      try {
        await target.delete();
      } on PathNotFoundException {
        // Nincs mit törölni: a törlés célja már teljesült.
      }
    }
  }

  // Egy sérült fájl nem állítja meg az appot: „nincs fiók", és a következő
  // regisztráció vagy csatlakozás felülírja (V3).
  void _logUnreadable(File file) => developer.log(
    'Unreadable web account file ignored: ${file.path}',
    name: 'web_access',
  );
}
