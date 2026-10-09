import 'package:web_server/src/legacy/budapest_time.dart';

/// Az exportált archívum-DB neve a csomagban.
const String exportArchiveFileName = 'archive.sqlite';

/// Az exportált webes DB neve a csomagban.
const String exportWebDatabaseFileName = 'web.sqlite';

/// A versenyek JSON-jának neve a csomagban (ADR 0050 D8).
const String exportHistoryJsonFileName = 'foretack-history.json';

/// A csomag leírásának neve.
const String exportReadmeFileName = 'README.txt';

/// Az STW-korrekciók helye a csomagban (ADR 0052 D9).
const String exportStwCorrectionsFileName = 'config/stw-corrections.json';

/// A csomag alapneve a [exportedAt] budapesti napjával:
/// `foretack-history-<YYYY-MM-DD>` (ADR 0050 D8). Ez a letöltött fájl
/// neve `.tar.gz`-vel, és a csomagbeli könyvtár neve (Addendum 3 G5).
String exportBaseName(DateTime exportedAt) =>
    'foretack-history-${budapestDayOf(exportedAt).toIso()}';
