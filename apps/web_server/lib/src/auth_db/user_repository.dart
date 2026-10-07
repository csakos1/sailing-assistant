import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/auth_user.dart';
import 'package:web_server/src/auth_db/epoch_millis.dart';

/// A `users` tábla olvasó-írója (ADR 0051 D2, D10).
class UserRepository {
  /// Repository a [_database] fölött.
  UserRepository(this._database);

  final AuthDatabase _database;

  /// Az `owner`, vagy `null`, ha még nincs.
  Future<AuthUser?> owner() async {
    final query = _database.select(_database.users)
      ..where((row) => row.role.equals(UserRole.owner.name));
    final row = await query.getSingleOrNull();
    return row == null ? null : authUserFromRow(row);
  }

  /// Az [id] fiók, vagy `null`, ha nincs ilyen.
  Future<AuthUser?> get(String id) async {
    final query = _database.select(_database.users)
      ..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : authUserFromRow(row);
  }

  /// Új fiók; a visszaolvasott rekord.
  ///
  /// Második `owner` beszúrásakor a DB egyedi indexe hibát dob: a hívó a
  /// tranzakcióban előbb az [owner]-t nézi.
  Future<AuthUser> insert({
    required String id,
    required String name,
    required UserRole role,
    required DateTime now,
  }) async {
    final row = await _database
        .into(_database.users)
        .insertReturning(
          UsersCompanion.insert(
            id: id,
            name: name,
            role: role.name,
            createdAtMs: toEpochMillis(now),
          ),
        );
    return authUserFromRow(row);
  }
}

/// Egy `users` sor mint [AuthUser]; a repository-k közös leképezése.
AuthUser authUserFromRow(UserRow row) => AuthUser(
  id: row.id,
  name: row.name,
  role: UserRole.values.byName(row.role),
  createdAt: fromEpochMillis(row.createdAtMs),
  passwordSetAt: fromOptionalEpochMillis(row.passwordSetAtMs),
);
