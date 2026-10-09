import 'dart:io';

import 'package:drift/native.dart';
import 'package:web_server/src/auth_db/auth_database.dart';

/// Mennyit vár egy CLI, ha a futó szerver épp ír az `auth.sqlite`-ba.
const Duration cliBusyTimeout = Duration(seconds: 5);

/// Az `auth.sqlite` megnyitása a VPS-es CLI-knek (ADR 0052 D10).
///
/// A szerver közben futhat; a `busy_timeout` nélkül egy épp folyó szerveres
/// írás (pl. az óránkénti aktivitás-frissítés) azonnali `SQLITE_BUSY`-t adna,
/// és a CLI veremkiírással állna le.
AuthDatabase openAuthDatabaseForCli(String path) => AuthDatabase(
  NativeDatabase(
    File(path),
    setup: (database) => database.execute(
      'PRAGMA busy_timeout = ${cliBusyTimeout.inMilliseconds}',
    ),
  ),
);
