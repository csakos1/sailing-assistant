import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/sessions_table.dart';
import 'package:web_server/src/auth_db/users_table.dart';

/// A belépési események (ADR 0051 D7, Addendum 3 K9, Addendum 6 N5).
///
/// Minden új session egy sort ír. A fiók törlése az eseményeit is viszi; a
/// munkamenet törlése után az esemény megmarad (`session_id` NULL), így a
/// szalag a lezárt gyanús belépést is mutathatja a nyugtázásig. A böngésző
/// helye és a jóváhagyó telefon országa a belépés pillanatában rögzül.
///
/// Row-class: `LoginEventRow`.
@DataClassName('LoginEventRow')
class LoginEvents extends Table {
  TextColumn get id => text()();
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get sessionId => text().nullable().references(
    Sessions,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get method => text()();
  TextColumn get ip => text()();
  TextColumn get browser => text().nullable()();
  TextColumn get os => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get phoneCountry => text().nullable()();
  BoolColumn get isSuspicious => boolean()();
  IntColumn get createdAtMs => integer()();
  IntColumn get acknowledgedAtMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (method IN ('qr', 'password', 'recoveryCode'))",
  ];
}
