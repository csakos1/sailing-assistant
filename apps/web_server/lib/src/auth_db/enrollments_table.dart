import 'package:drift/drift.dart';

/// Az `owner` telefonjának regisztrációs tokenjei (ADR 0051 D3).
///
/// A tokennek csak a SHA-256 hash-e tárolódik. Az `owner_name` csak az első
/// `owner` létrehozásakor kell; ha már van `owner`, a token az ő új
/// eszközét regisztrálja.
///
/// Row-class: `EnrollmentRow`.
@DataClassName('EnrollmentRow')
class Enrollments extends Table {
  BlobColumn get tokenDigest => blob()();
  TextColumn get origin => text()();
  TextColumn get ownerName => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get expiresAtMs => integer()();
  IntColumn get usedAtMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {tokenDigest};
}
