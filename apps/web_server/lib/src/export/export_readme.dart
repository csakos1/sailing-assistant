import 'package:web_server/src/export/export_layout.dart';
import 'package:web_server/src/export/history_json_writer.dart';
import 'package:web_server/src/legacy/budapest_time.dart';

/// A csomag `README.txt`-je (ADR 0050 D8 + Addendum 3 G7): a fájlok
/// szerepe, az export ideje, a verziók és a kézi visszaállítás.
String exportReadme({
  required DateTime exportedAt,
  required int raceCount,
  required String serverVersion,
  required int archiveSchemaVersion,
  required int webSchemaVersion,
}) {
  final utc = exportedAt.toUtc();
  return '''
Foretack versenyarchívum — teljes export
=========================================

Export ideje:  ${_formatWallClock(utc)} UTC
               ${_formatWallClock(budapestWallClockOf(utc))} (Budapest)
Versenyek:     $raceCount
Szerver:       web_server $serverVersion

Fájlok
------
$exportArchiveFileName
    A telefonról feltöltött versenyek archívuma (a phone sémája,
    sémaverzió: $archiveSchemaVersion). Konzisztens mentés (VACUUM INTO).
$exportWebDatabaseFileName
    A webes adatok: eredmények, kézi versenyek, régi trackek, statisztika-
    és polár-cache (sémaverzió: $webSchemaVersion). Ugyanabból a
    pillanatból, mint az archívum.
$exportHistoryJsonFileName
    Minden verseny a webes szerződés formátumában: a napló sora
    ("summary") és a részletező (track, bóják, régi track).
    format: $historyJsonFormat, version: $historyJsonVersion.
$exportReadmeFileName
    Ez a leírás.

A .DAT és a polar.csv nem része az exportnak.

Visszaállítás kézzel
--------------------
1. A szerver leállítása (systemctl stop).
2. A két SQLite-fájl a szerver --archive és --web-db helyére másolva; a
   régi -wal és -shm fájlok törölve.
3. A szerver indítása; a polár-cache induláskor újraszámolódik, ha a
   polár vagy az STW-korrekció azóta változott.
''';
}

// ÉÉÉÉ-HH-NN ÓÓ:PP:MM, a mezők a kapott objektumból.
String _formatWallClock(DateTime value) {
  String two(int part) => part.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-${two(value.month)}-'
      '${two(value.day)} ${two(value.hour)}:${two(value.minute)}:'
      '${two(value.second)}';
}
