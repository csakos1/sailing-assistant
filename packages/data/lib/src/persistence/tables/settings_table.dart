import 'package:drift/drift.dart';

/// A kulcs-érték beállítás-tár (ADR 0011). Egy sor = egy beállítás; a `value`
/// sosem null — az érték törlése a sor törlése (delete-on-unset, lásd a
/// `SettingsRepositoryImpl`-t). A generált row-class `SettingRow`, a
/// `RaceRow`/`MarkRow` mintára.
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
