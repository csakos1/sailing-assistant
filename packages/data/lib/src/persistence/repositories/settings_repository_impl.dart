import 'dart:convert';
import 'dart:developer' as developer;

import 'package:data/src/persistence/app_database.dart';
import 'package:domain/domain.dart';

/// A [SettingsRepository] Drift-alapú implementációja (ADR 0011).
///
/// A `Settings` KV-tábla fölött dolgozik: egy kulcs egy sor. Két kulcs van:
/// az aktív race id-je és a Műszerek fül kézi versenyválasztása (JSON); a
/// `null` érték TÖRLI a sort (delete-on-unset), így restartkor nem
/// támasztunk fel befejezett vagy elvetett race-t. A KV-kulcs
/// implementáció-részlet — a domain csak a tipizált metódusokat látja.
class SettingsRepositoryImpl implements SettingsRepository {
  /// A `database` a Drift adatbázis. A beállítás-tár nem hordoz audit-időt,
  /// ezért a RaceRepositoryImpl-lel ellentétben itt nincs injektált óra.
  SettingsRepositoryImpl(this._database);

  final AppDatabase _database;

  static const String _activeRaceIdKey = 'active_race_id';
  static const String _instrumentsRaceChoiceKey = 'instruments_race_choice';

  // A nap ÉÉÉÉ-HH-NN alakban; a választás csak a naptári napra szól.
  static final RegExp _dayPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  @override
  Future<String?> readActiveRaceId() => _read(_activeRaceIdKey);

  @override
  Future<void> writeActiveRaceId(String? id) => _write(_activeRaceIdKey, id);

  @override
  Future<InstrumentsRaceChoice?> readInstrumentsRaceChoice() async {
    final value = await _read(_instrumentsRaceChoiceKey);
    if (value == null) return null;
    final choice = _decodeChoice(value);
    // Egy olvashatatlan érték nem állíthatja meg a kiválasztást: a szabály
    // kézi választás nélkül dönt.
    if (choice == null) {
      developer.log(
        'unreadable instruments race choice ignored',
        name: 'SettingsRepository',
        level: 900,
      );
    }
    return choice;
  }

  @override
  Future<void> writeInstrumentsRaceChoice(InstrumentsRaceChoice? choice) =>
      _write(
        _instrumentsRaceChoiceKey,
        choice == null ? null : _encodeChoice(choice),
      );

  static String _encodeChoice(InstrumentsRaceChoice choice) {
    final day = choice.chosenOnLocalDay;
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    final year = day.year.toString().padLeft(4, '0');
    return jsonEncode({
      'raceId': choice.raceId,
      'day': '$year-$month-$dayOfMonth',
    });
  }

  static InstrumentsRaceChoice? _decodeChoice(String value) {
    final Object? decoded;
    try {
      decoded = jsonDecode(value);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) return null;
    final raceId = decoded['raceId'];
    final day = decoded['day'];
    if (raceId is! String || raceId.isEmpty || day is! String) return null;
    final match = _dayPattern.firstMatch(day);
    if (match == null) return null;
    // Illeszkedéskor a minta mindhárom csoportja megvan, a `!` nem dobhat.
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final dayOfMonth = int.parse(match.group(3)!);
    final date = DateTime(year, month, dayOfMonth);
    // Egy nem létező nap (pl. 02-31) a DateTime-ban átfordulna.
    if (date.month != month || date.day != dayOfMonth) return null;
    return InstrumentsRaceChoice(raceId: raceId, chosenOnLocalDay: date);
  }

  /// Egy kulcs értéke, vagy `null`, ha nincs ilyen sor.
  Future<String?> _read(String key) async {
    final row = await (_database.select(
      _database.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// Upsert egy kulcs-értékre; `null` érték TÖRLI a sort (delete-on-unset).
  Future<void> _write(String key, String? value) async {
    if (value == null) {
      await (_database.delete(
        _database.settings,
      )..where((s) => s.key.equals(key))).go();
      return;
    }
    await _database
        .into(_database.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value),
        );
  }
}
