import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/enrollment_record.dart';
import 'package:web_server/src/auth_db/epoch_millis.dart';

/// Az `enrollments` tábla olvasó-írója (ADR 0051 D3).
class EnrollmentRepository {
  /// Repository a [_database] fölött.
  EnrollmentRepository(this._database);

  final AuthDatabase _database;

  /// Új regisztrációs token a [tokenDigest] hash-sel.
  Future<void> insert({
    required Uint8List tokenDigest,
    required String origin,
    required DateTime now,
    required DateTime expiresAt,
    String? ownerName,
  }) async {
    await _database
        .into(_database.enrollments)
        .insert(
          EnrollmentsCompanion.insert(
            tokenDigest: tokenDigest,
            origin: origin,
            ownerName: Value(ownerName),
            createdAtMs: toEpochMillis(now),
            expiresAtMs: toEpochMillis(expiresAt),
          ),
        );
  }

  /// A [tokenDigest] token felhasználása [now] időponttal: a token adatai,
  /// vagy `null`, ha nincs ilyen, lejárt, vagy már felhasználták.
  ///
  /// Egyetlen feltételes `UPDATE … RETURNING`: két egyidejű beváltásból
  /// csak az egyik kapja meg a tokent.
  Future<EnrollmentRecord?> consume(
    Uint8List tokenDigest, {
    required DateTime now,
  }) async {
    final nowMillis = toEpochMillis(now);
    final rows =
        await (_database.update(_database.enrollments)..where(
              (row) =>
                  row.tokenDigest.equals(tokenDigest) &
                  row.usedAtMs.isNull() &
                  row.expiresAtMs.isBiggerThanValue(nowMillis),
            ))
            .writeReturning(EnrollmentsCompanion(usedAtMs: Value(nowMillis)));
    if (rows.isEmpty) return null;
    final row = rows.single;
    return EnrollmentRecord(
      origin: row.origin,
      ownerName: row.ownerName,
      createdAt: fromEpochMillis(row.createdAtMs),
      expiresAt: fromEpochMillis(row.expiresAtMs),
    );
  }
}
