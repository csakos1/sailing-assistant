import 'dart:io';

import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:web_server/src/server_log.dart';
import 'package:web_server/src/web_db/web_database.dart';

/// A mentés két adatbázisának megnyitott másolata.
typedef ArchiveCopies = ({AppDatabase archive, WebDatabase webDatabase});

/// A [body] a mentés két SQLite-fájljának megnyitott másolatán fut
/// (`docs/PLAN.md` P.1, P.3).
///
/// A két fájl a [workDirPath] alatti, [tempPrefix] kezdetű ideiglenes
/// könyvtárba másolódik, és a másolat nyílik meg, mert a phone DB
/// megnyitáskor WAL-ra áll: az eredeti mentés így érintetlen marad. A
/// végén mindkét adatbázis bezárul és a könyvtár törlődik, a [body] hibája
/// esetén is.
///
/// A bemenet egyetlen fájlos mentés legyen (VACUUM INTO / .backup); egy élő,
/// WAL-os adatbázis -wal tartalma nem másolódik.
Future<T> withArchiveCopies<T>({
  required String archivePath,
  required String webDbPath,
  required String workDirPath,
  required String tempPrefix,
  required ServerLog log,
  required Future<T> Function(ArchiveCopies copies) body,
}) async {
  final workDir = await Directory(workDirPath).createTemp(tempPrefix);
  try {
    log('Másolás: ${workDir.path}');
    final archiveCopy = await File(
      archivePath,
    ).copy('${workDir.path}/archive.sqlite');
    final webCopy = await File(webDbPath).copy('${workDir.path}/web.sqlite');
    return await _withOpened(archiveCopy, webCopy, body);
  } finally {
    try {
      await workDir.delete(recursive: true);
    } on FileSystemException catch (error) {
      // A törlés hibája ne takarja el az eredeti hibát.
      log('A másolat nem törölhető: ${workDir.path}, ${error.message}');
    }
  }
}

Future<T> _withOpened<T>(
  File archiveCopy,
  File webCopy,
  Future<T> Function(ArchiveCopies copies) body,
) async {
  final archive = AppDatabase(NativeDatabase.createInBackground(archiveCopy));
  final webDatabase = WebDatabase(NativeDatabase.createInBackground(webCopy));
  try {
    return await body((archive: archive, webDatabase: webDatabase));
  } finally {
    // Az egyik hibája se hagyja nyitva a másikat (és a háttér-isolate-jét).
    try {
      await archive.close();
    } finally {
      await webDatabase.close();
    }
  }
}
