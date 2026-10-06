import 'dart:io';

import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:web_server/src/race/archive_read_services.dart';
import 'package:web_server/src/server_log.dart';
import 'package:web_server/src/web_db/web_database.dart';

/// Egy megnyitott pillanatkép: az olvasó szolgáltatások a két másolat
/// fölött, és a lezárásuk (ADR 0050 Addendum 3 G3).
final class OpenedSnapshot {
  /// Pillanatkép a [services] szolgáltatásokkal; a [close] zárja le.
  const OpenedSnapshot({required this.services, required this.close});

  /// A napló és a részletező a másolatokból.
  final ArchiveReadServices services;

  /// A két kapcsolat lezárása; utána a fájlok becsomagolhatók.
  final Future<void> Function() close;
}

/// Egy pillanatkép megnyitója az [archiveCopy] és a [webCopy] másolatra.
typedef SnapshotOpener =
    Future<OpenedSnapshot> Function({
      required File archiveCopy,
      required File webCopy,
    });

/// A két másolat megnyitása háttér-isolate kapcsolattal, hogy a JSON
/// olvasása ne blokkolja a szerver event loopját.
///
/// A phone `AppDatabase` megnyitáskor WAL-ra állítja a másolatot; adat nem
/// változik, és a lezárás a `-wal` fájlt visszaírja és törli.
Future<OpenedSnapshot> openDatabaseSnapshot({
  required File archiveCopy,
  required File webCopy,
  ServerLog log = ignoreServerLog,
}) async {
  final archive = AppDatabase(NativeDatabase.createInBackground(archiveCopy));
  final webDatabase = WebDatabase(NativeDatabase.createInBackground(webCopy));
  return OpenedSnapshot(
    services: ArchiveReadServices.over(
      archive: archive,
      webDatabase: webDatabase,
      log: log,
    ),
    close: () async {
      // Az egyik hibája se hagyja nyitva a másikat (és a háttér-isolate-jét).
      try {
        await archive.close();
      } finally {
        await webDatabase.close();
      }
    },
  );
}
