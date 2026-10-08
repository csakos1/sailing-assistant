import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/epoch_millis.dart';

/// A `recovery_codes` tábla olvasó-írója (ADR 0051 D6).
class RecoveryCodeRepository {
  /// Repository a [_database] fölött.
  RecoveryCodeRepository(this._database);

  final AuthDatabase _database;

  /// A [userId] fiók [codeDigest] kódjának felhasználása [now]-kor: `true`,
  /// ha élt (még nem használták) és most elhasználódott (Addendum 6 N2).
  ///
  /// Egyetlen feltételes `UPDATE`: két egyidejű beváltásból egy nyer.
  Future<bool> consume(
    Uint8List codeDigest, {
    required String userId,
    required DateTime now,
  }) async {
    final updated =
        await (_database.update(_database.recoveryCodes)..where(
              (row) =>
                  row.codeDigest.equals(codeDigest) &
                  row.userId.equals(userId) &
                  row.usedAtMs.isNull(),
            ))
            .write(RecoveryCodesCompanion(usedAtMs: Value(toEpochMillis(now))));
    return updated == 1;
  }

  /// A [userId] fiók még fel nem használt kódjainak száma (18l).
  Future<int> countUnused(String userId) async {
    final codes = _database.recoveryCodes;
    final count = codes.codeDigest.count();
    final query = _database.selectOnly(codes)
      ..addColumns([count])
      ..where(codes.userId.equals(userId) & codes.usedAtMs.isNull());
    return (await query.getSingle()).read(count) ?? 0;
  }

  /// Mikor készült a [userId] fiók mostani kódkészlete (Addendum 10 Z12);
  /// `null`, ha nincs kódja.
  ///
  /// A tíz kód egyszerre készül ([replaceAll]), ezért a legkésőbbi
  /// létrehozás a készleté; a felhasznált kódok is számítanak, mert a
  /// készlet akkor is ugyanaz.
  Future<DateTime?> latestCreatedAt(String userId) async {
    final codes = _database.recoveryCodes;
    final latest = codes.createdAtMs.max();
    final query = _database.selectOnly(codes)
      ..addColumns([latest])
      ..where(codes.userId.equals(userId));
    return fromOptionalEpochMillis((await query.getSingle()).read(latest));
  }

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
