import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/epoch_millis.dart';

/// A `recovery_codes` tábla olvasó-írója (ADR 0051 D6).
class RecoveryCodeRepository {
  /// Repository a [_database] fölött.
  RecoveryCodeRepository(this._database);

  final AuthDatabase _database;

  /// A [userId] fiók összes kódjának cseréje a [digests] hash-ekre.
  ///
  /// A régi kódok (a felhasználtak is) törlődnek, így egy új készlet után
  /// csak az új érvényes. A hívó tranzakcióban futtatja, hogy a csere ne
  /// maradhasson félbe.
  Future<void> replaceAll(
    String userId,
    List<Uint8List> digests, {
    required DateTime now,
  }) async {
    await (_database.delete(
      _database.recoveryCodes,
    )..where((row) => row.userId.equals(userId))).go();
    await _database.batch((batch) {
      batch.insertAll(_database.recoveryCodes, [
        for (final digest in digests)
          RecoveryCodesCompanion.insert(
            codeDigest: digest,
            userId: userId,
            createdAtMs: toEpochMillis(now),
          ),
      ]);
    });
  }
}
