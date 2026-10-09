import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:phone/features/web_access/data/pending_join.dart';
import 'package:phone/features/web_access/data/pending_join_codec.dart';
import 'package:phone/features/web_access/data/pending_join_store.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/data/web_account_codec.dart';
import 'package:phone/features/web_access/data/web_account_store.dart';

/// A fiók-fájl neve az app privát könyvtárában (V3).
const String webAccountFileName = 'web_account.json';

/// A webes fiók vagy a függő csatlakozási kérelem egy app-privát
/// JSON-fájlban (ADR 0051 Addendum 8 V3, Addendum 9 X4).
///
/// Szándékosan nem a versenyek Drift-DB-jében él: egy fiók-csere vagy egy
/// visszavont eszköz takarítása így versenyt nem érinthet. Az írás egy
/// ideiglenes fájlba megy, utána `rename` cseréli: egy félbemaradt írás
/// nem hagy fél fájlt. A fájl vagy fiókot, vagy kérelmet hord, ezért egy
/// írás mindig a teljes korábbi tartalmat cseréli.
class FileWebAccountStore implements WebAccountStore, PendingJoinStore {
  /// Tár a [_directory] által adott könyvtárban.
  FileWebAccountStore(this._directory);

  final Future<Directory> Function() _directory;

  Future<File> get _file async =>
      File('${(await _directory()).path}/$webAccountFileName');

  @override
  Future<WebAccount?> read() async {
    final json = await _readJson();
    if (json == null) return null;
    final account = decodeWebAccount(json);
    if (account == null && decodePendingJoinFile(json) == null) {
      _logUnreadable();
    }
    return account;
  }

  @override
  Future<PendingJoin?> readPendingJoin() async {
    final json = await _readJson();
    if (json == null) return null;
    final pending = decodePendingJoinFile(json);
    if (pending == null && decodeWebAccount(json) == null) _logUnreadable();
    return pending;
  }

  @override
  Future<void> write(WebAccount account) =>
      _writeJson(encodeWebAccount(account));

  @override
  Future<void> writePendingJoin(PendingJoin pending) =>
      _writeJson(encodePendingJoinFile(pending));

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

  // A fájl JSON-tartalma, vagy `null`, ha nincs vagy nem olvasható.
  Future<Object?> _readJson() async {
    final file = await _file;
    final String text;
    try {
      text = await file.readAsString();
    } on PathNotFoundException {
      return null;
    } on FileSystemException {
      // Pl. nem UTF-8 tartalom: ugyanaz, mint egy sérült JSON.
      _logUnreadable();
      return null;
    }
    try {
      return jsonDecode(text);
    } on FormatException {
      _logUnreadable();
      return null;
    }
  }

  Future<void> _writeJson(Map<String, Object?> json) async {
    final file = await _file;
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(json), flush: true);
    await temporary.rename(file.path);
  }

  // Egy sérült fájl nem állítja meg az appot: „nincs fiók", és a következő
  // regisztráció vagy csatlakozás felülírja (V3).
  void _logUnreadable() => developer.log(
    'Unreadable web account file ignored: $webAccountFileName',
    name: 'web_access',
  );
}
