import 'dart:io';

/// A [paths] (kapcsoló neve → útvonal) közül a nem létező fájlok
/// hibasorai, a kapcsolók sorrendjében (ADR 0050 Addendum 1 E5).
///
/// A CLI-k a DB-k megnyitása előtt hívják: a Drift egy nem létező fájl
/// helyén csendben üres adatbázist hozna létre, és a próbafuttatás egy
/// elgépelt útvonalnál is „semmi teendő"-t mutatna.
List<String> missingFileLines(Map<String, String> paths) => [
  for (final MapEntry(key: option, value: path) in paths.entries)
    if (!File(path).existsSync()) '--$option: a fájl nem létezik: $path',
];
