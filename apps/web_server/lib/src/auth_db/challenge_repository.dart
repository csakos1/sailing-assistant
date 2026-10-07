import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/epoch_millis.dart';

/// A `challenges` tábla olvasó-írója (ADR 0051 Addendum 3 K2, K3).
class ChallengeRepository {
  /// Repository a [_database] fölött.
  ChallengeRepository(this._database);

  final AuthDatabase _database;

  /// Új kihívás a [digest] hash-sel a [deviceId] eszköznek.
  Future<void> insert({
    required Uint8List digest,
    required String deviceId,
    required DateTime expiresAt,
  }) async {
    await _database
        .into(_database.challenges)
        .insert(
          ChallengesCompanion.insert(
            digest: digest,
            deviceId: deviceId,
            expiresAtMs: toEpochMillis(expiresAt),
          ),
        );
  }

  /// A [digest] kihívás felhasználása a [deviceId] eszköznek: `true`, ha
  /// élt és most elhasználódott.
  ///
  /// Egyetlen feltételes `DELETE`: két egyidejű beváltásból csak az egyik
  /// sikerül, és egy más eszköznek szóló kihívás nem használható.
  Future<bool> consume(
    Uint8List digest, {
    required String deviceId,
    required DateTime now,
  }) async {
    final deleted =
        await (_database.delete(_database.challenges)..where(
              (row) =>
                  row.digest.equals(digest) &
                  row.deviceId.equals(deviceId) &
                  row.expiresAtMs.isBiggerThanValue(toEpochMillis(now)),
            ))
            .go();
    return deleted == 1;
  }

  /// A [now]-kor már lejárt kihívások törlése.
  Future<void> deleteExpired(DateTime now) async {
    await (_database.delete(_database.challenges)..where(
          (row) => row.expiresAtMs.isSmallerOrEqualValue(toEpochMillis(now)),
        ))
        .go();
  }
}
