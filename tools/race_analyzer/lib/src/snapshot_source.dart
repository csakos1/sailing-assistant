import 'dart:convert';
import 'dart:io';

import 'package:race_analyzer/src/snapshot_read_model.dart';
import 'package:sqlite3/sqlite3.dart';

/// JSON-lines fixturabol olvas (egy sor = egy snapshot JSON), idorend
/// szerint (a kiiras mar idorendu). A fixture-teszt es a `.jsonl` CLI-ut
/// hasznalja; nincs natív fuggoseg (sqlite3 nem kell hozza).
List<AnalyzerSnapshot> readSnapshotsFromJsonl(String path) {
  final out = <AnalyzerSnapshot>[];
  for (final line in File(path).readAsLinesSync()) {
    final snap = parseSnapshotLine(line);
    if (snap != null) out.add(snap);
  }
  return out;
}

/// A Drift `snapshot_logs` tablabol olvas egy adott `raceId`-re, idorendben
/// (`package:sqlite3`, kozvetlen SQL — a Flutter-kototott
/// `RaceSnapshot.fromJson`-t szandekosan kerulve, ADR 0025 D2). A WAL-fajl
/// (ha a fo .sqlite mellett van) automatikusan beolvasodik.
List<AnalyzerSnapshot> readSnapshotsFromDb(String dbPath, String raceId) {
  final db = sqlite3.open(dbPath, mode: OpenMode.readOnly);
  try {
    final rows = db.select(
      'SELECT snapshot_json FROM snapshot_logs '
      'WHERE race_id = ? ORDER BY timestamp',
      [raceId],
    );
    return [
      for (final row in rows)
        parseSnapshot(
          jsonDecode(row['snapshot_json'] as String) as Map<String, dynamic>,
        ),
    ];
  } finally {
    db.close();
  }
}

/// Egy race osszegzese a `snapshot_logs`-ban (a CLI race-valasztasahoz: a tabla
/// minden eddigi session adatat hordozza, ezert egy `raceId`-re kell szurni).
class RaceSummary {
  /// Osszegzo egy race-rol.
  const RaceSummary({
    required this.raceId,
    required this.snapshotCount,
    required this.firstTick,
    required this.lastTick,
    required this.markNames,
    this.raceName,
  });

  /// A race azonositoja (a `snapshot_logs.race_id`).
  final String raceId;

  /// A race neve a `races` tablabol, vagy `null`, ha nem elerheto.
  final String? raceName;

  /// A race-hez tartozo snapshot-sorok szama.
  final int snapshotCount;

  /// A legkorabbi tick ideje.
  final DateTime firstTick;

  /// A legkesobbi tick ideje.
  final DateTime lastTick;

  /// A snapshotokban latott aktiv-boja-nevek (a kurzus azonositasahoz).
  final Set<String> markNames;

  /// A race idotartama (utolso − elso tick).
  Duration get span => lastTick.difference(firstTick);
}

/// Listazza a `snapshot_logs`-ban szereplo race-eket (idorend szerint az
/// utolso tick alapjan). A race-nevek a `races` tablabol jonnek, ha elerheto.
List<RaceSummary> listRacesInDb(String dbPath) {
  final db = sqlite3.open(dbPath, mode: OpenMode.readOnly);
  try {
    final names = _readRaceNames(db);
    final byRace = <String, _RaceAccumulator>{};
    final rows = db.select(
      'SELECT race_id, snapshot_json FROM snapshot_logs ORDER BY timestamp',
    );
    for (final row in rows) {
      final raceId = row['race_id'] as String;
      final snap = parseSnapshot(
        jsonDecode(row['snapshot_json'] as String) as Map<String, dynamic>,
      );
      (byRace[raceId] ??= _RaceAccumulator(snap.tickTime)).add(snap);
    }
    final summaries = [
      for (final entry in byRace.entries)
        RaceSummary(
          raceId: entry.key,
          raceName: names[entry.key],
          snapshotCount: entry.value.count,
          firstTick: entry.value.first,
          lastTick: entry.value.last,
          markNames: entry.value.markNames,
        ),
    ];
    return summaries..sort((a, b) => a.lastTick.compareTo(b.lastTick));
  } finally {
    db.close();
  }
}

// A races tabla opcionalis (regi DB nelkule is mukodjon); hiba eseten ures map.
Map<String, String?> _readRaceNames(Database db) {
  try {
    return <String, String?>{
      for (final row in db.select('SELECT id, name FROM races'))
        row['id'] as String: row['name'] as String?,
    };
  } on SqliteException {
    return const <String, String?>{};
  }
}

class _RaceAccumulator {
  _RaceAccumulator(DateTime seed) : first = seed, last = seed;

  DateTime first;
  DateTime last;
  int count = 0;
  final Set<String> markNames = <String>{};

  void add(AnalyzerSnapshot snap) {
    count++;
    if (snap.tickTime.isBefore(first)) first = snap.tickTime;
    if (snap.tickTime.isAfter(last)) last = snap.tickTime;
    final name = snap.markName;
    if (name != null) markNames.add(name);
  }
}
