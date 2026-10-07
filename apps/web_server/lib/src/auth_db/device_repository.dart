import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/auth_device.dart';
import 'package:web_server/src/auth_db/auth_user.dart';
import 'package:web_server/src/auth_db/epoch_millis.dart';
import 'package:web_server/src/auth_db/user_repository.dart';

/// Egy eszköz a fiókjával együtt (a `revoke_device` listájához).
typedef DeviceWithUser = ({AuthDevice device, AuthUser user});

/// A `devices` tábla olvasó-írója (ADR 0051 D3, D10).
class DeviceRepository {
  /// Repository a [_database] fölött.
  DeviceRepository(this._database);

  final AuthDatabase _database;

  /// Új eszköz; a visszaolvasott rekord.
  ///
  /// A [publicKey] egy már ellenőrzött P-256 SubjectPublicKeyInfo; ha már
  /// egy másik eszközé, a DB egyedi megszorítása hibát dob.
  Future<AuthDevice> insert({
    required String id,
    required String userId,
    required Uint8List publicKey,
    required String name,
    required String model,
    required DateTime now,
  }) async {
    final row = await _database
        .into(_database.devices)
        .insertReturning(
          DevicesCompanion.insert(
            id: id,
            userId: userId,
            publicKey: publicKey,
            name: name,
            model: model,
            createdAtMs: toEpochMillis(now),
          ),
        );
    return _toDevice(row);
  }

  /// Az [id] eszköz (visszavontan is), vagy `null`, ha nincs ilyen.
  Future<AuthDevice?> get(String id) async {
    final query = _database.select(_database.devices)
      ..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDevice(row);
  }

  /// Minden eszköz a fiókjával, fióknév és regisztrációs idő szerint.
  Future<List<DeviceWithUser>> listAll() async {
    final devices = _database.devices;
    final users = _database.users;
    final query =
        _database.select(devices).join([
          innerJoin(users, users.id.equalsExp(devices.userId)),
        ])..orderBy([
          OrderingTerm.asc(users.name),
          OrderingTerm.asc(devices.createdAtMs),
        ]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          device: _toDevice(row.readTable(devices)),
          user: authUserFromRow(row.readTable(users)),
        ),
    ];
  }

  /// Az [id] eszköz visszavonása [now] időponttal.
  ///
  /// `true`, ha az eszköz aktív volt és most visszavonódott; `false`, ha
  /// nincs ilyen, vagy már vissza volt vonva (a régi időpont megmarad).
  Future<bool> revoke(String id, {required DateTime now}) async {
    final updated =
        await (_database.update(_database.devices)
              ..where((row) => row.id.equals(id) & row.revokedAtMs.isNull()))
            .write(DevicesCompanion(revokedAtMs: Value(toEpochMillis(now))));
    return updated == 1;
  }

  AuthDevice _toDevice(DeviceRow row) => AuthDevice(
    id: row.id,
    userId: row.userId,
    publicKey: row.publicKey,
    name: row.name,
    model: row.model,
    createdAt: fromEpochMillis(row.createdAtMs),
    lastUsedAt: fromOptionalEpochMillis(row.lastUsedAtMs),
    revokedAt: fromOptionalEpochMillis(row.revokedAtMs),
  );
}
