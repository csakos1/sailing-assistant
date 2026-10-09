import 'package:drift/drift.dart';

/// A webes fiókok (ADR 0051 D2, Addendum 2 J7).
///
/// A szerep a `UserRole` neve. Az időpontok UTC epoch-milliszekundumban:
/// így nincs zóna- és másodperc-kerekítési csapda (vö. a Drift
/// `dateTime()` másodperces, helyi idős visszaolvasásával).
///
/// Row-class: `UserRow`.
@DataClassName('UserRow')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  TextColumn get passwordHash => text().nullable()();
  IntColumn get passwordSetAtMs => integer().nullable()();
  IntColumn get createdAtMs => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (role IN ('owner', 'crew'))",
  ];
}
