import 'package:data/src/persistence/app_database.dart';
import 'package:domain/domain.dart';

/// A [SettingsRepository] Drift-alapú implementációja (ADR 0011).
///
/// A `Settings` KV-tábla fölött dolgozik: egy kulcs egy sor. Az aktív-race-id
/// az egyetlen v1-beli kulcs; a `null` érték TÖRLI a sort (delete-on-unset),
/// így restartkor nem támasztunk fel befejezett vagy elvetett race-t. A
/// KV-kulcs implementáció-részlet — a domain csak a tipizált metódusokat látja.
class SettingsRepositoryImpl implements SettingsRepository {
  /// A `database` a Drift adatbázis. A beállítás-tár nem hordoz audit-időt,
  /// ezért a RaceRepositoryImpl-lel ellentétben itt nincs injektált óra.
  SettingsRepositoryImpl(this._database);

  final AppDatabase _database;

  static const String _activeRaceIdKey = 'active_race_id';

  @override
  Future<String?> readActiveRaceId() => _read(_activeRaceIdKey);

  @override
  Future<void> writeActiveRaceId(String? id) => _write(_activeRaceIdKey, id);

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
