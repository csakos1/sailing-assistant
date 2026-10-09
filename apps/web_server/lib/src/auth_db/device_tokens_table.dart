import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/devices_table.dart';

/// A telefonok rövid életű eszköz-tokenjei (ADR 0051 Addendum 3 K3).
///
/// Csak a token SHA-256 hash-e tárolódik; a keresés erre történik.
///
/// Row-class: `DeviceTokenRow`.
@DataClassName('DeviceTokenRow')
class DeviceTokens extends Table {
  BlobColumn get digest => blob()();
  TextColumn get deviceId =>
      text().references(Devices, #id, onDelete: KeyAction.cascade)();
  IntColumn get expiresAtMs => integer()();

  @override
  Set<Column> get primaryKey => {digest};
}
