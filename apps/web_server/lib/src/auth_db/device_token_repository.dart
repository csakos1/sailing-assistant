import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/epoch_millis.dart';

/// A `device_tokens` tábla olvasó-írója (ADR 0051 Addendum 3 K3).
class DeviceTokenRepository {
  /// Repository a [_database] fölött.
  DeviceTokenRepository(this._database);

  final AuthDatabase _database;

  /// Új eszköz-token a [digest] hash-sel a [deviceId] eszköznek.
  Future<void> insert({
    required Uint8List digest,
    required String deviceId,
    required DateTime expiresAt,
  }) async {
    await _database
        .into(_database.deviceTokens)
        .insert(
          DeviceTokensCompanion.insert(
            digest: digest,
            deviceId: deviceId,
            expiresAtMs: toEpochMillis(expiresAt),
          ),
        );
  }

  /// A [digest] token eszköze, vagy `null`, ha nincs ilyen élő token.
  ///
  /// Hogy az eszköz vissza van-e vonva, azt a hívó nézi meg: így a
  /// visszavont eszköz pontos hibát kaphat (18d-5).
  Future<String?> deviceIdOf(Uint8List digest, {required DateTime now}) async {
    final query = _database.select(_database.deviceTokens)
      ..where(
        (row) =>
            row.digest.equals(digest) &
            row.expiresAtMs.isBiggerThanValue(toEpochMillis(now)),
      );
    return (await query.getSingleOrNull())?.deviceId;
  }

  /// A [now]-kor már lejárt tokenek törlése.
  Future<void> deleteExpired(DateTime now) async {
    await (_database.delete(_database.deviceTokens)..where(
          (row) => row.expiresAtMs.isSmallerOrEqualValue(toEpochMillis(now)),
        ))
        .go();
  }
}
