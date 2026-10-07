import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/challenges_table.dart';
import 'package:web_server/src/auth_db/device_tokens_table.dart';
import 'package:web_server/src/auth_db/devices_table.dart';
import 'package:web_server/src/auth_db/enrollments_table.dart';
import 'package:web_server/src/auth_db/login_requests_table.dart';
import 'package:web_server/src/auth_db/recovery_codes_table.dart';
import 'package:web_server/src/auth_db/sessions_table.dart';
import 'package:web_server/src/auth_db/users_table.dart';

part 'auth_database.g.dart';

/// A hitelesítés saját adatbázisa, az `auth.sqlite` (ADR 0051 D10).
///
/// Külön fájl a `web.sqlite`-tól: az S14 export azt másolja, a kulcsok és a
/// jelszó-hash viszont nem kerülhetnek egy letölthető csomagba. A v1 séma
/// a deploy (S8) előtt migráció nélkül bővül (Addendum 2 J7, Addendum 3
/// K13): az A2b a csatlakozási kérelmekkel és a belépési eseményekkel.
@DriftDatabase(
  tables: [
    Users,
    Devices,
    Enrollments,
    Challenges,
    DeviceTokens,
    Sessions,
    LoginRequests,
    RecoveryCodes,
  ],
)
class AuthDatabase extends _$AuthDatabase {
  /// Adatbázis a hívó által adott [executor]-ral (szerveren fájl, tesztben
  /// memória).
  AuthDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      // Legfeljebb egy `owner` lehet; ezt a DB is őrzi, nem csak a kód.
      await customStatement(
        'CREATE UNIQUE INDEX users_single_owner ON users (role) '
        "WHERE role = 'owner'",
      );
    },
    // Az SQLite alapból nem érvényesíti a külső kulcsokat; e nélkül a fiók
    // törlése nem vinné magával az eszközeit.
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
