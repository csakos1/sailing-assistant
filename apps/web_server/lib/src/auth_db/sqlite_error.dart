import 'package:drift/native.dart' show SqliteException;
// A drift a háttér-isolate hibáit csak ebben a kísérleti könyvtárban
// exportált típusba csomagolja; ha egy drift-frissítés megszünteti, az
// analyze azonnal jelzi.
// ignore: experimental_member_use
import 'package:drift/remote.dart' show DriftRemoteException;

/// SQLite-hiba-e az [error], közvetlenül vagy a háttér-isolate-ból
/// becsomagolva.
///
/// A szerver a DB-t `NativeDatabase.createInBackground`-dal nyitja: ott egy
/// egyedi index sértése `DriftRemoteException`-ként jön, a valódi ok a
/// `remoteCause`-ban van; a tesztek memóriabeli DB-jén közvetlenül
/// `SqliteException`.
bool isSqliteError(Object error) => switch (error) {
  SqliteException() => true,
  DriftRemoteException(:final remoteCause) => remoteCause is SqliteException,
  _ => false,
};
