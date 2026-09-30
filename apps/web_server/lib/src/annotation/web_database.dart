import 'package:drift/drift.dart';
import 'package:web_server/src/annotation/race_annotations_table.dart';

part 'web_database.g.dart';

/// A webes annotációk saját adatbázisa (ADR 0047 D5 + Addendum 3 C3).
///
/// Független az `AppDatabase`-től: saját fájl, saját migrációs lánc. Így az
/// app sémaváltása nem érinti a kézzel rögzített eredményeket, és egy
/// archívum-újraépítés (újraimport) sem veszíti el őket.
@DriftDatabase(tables: [RaceAnnotations])
class WebDatabase extends _$WebDatabase {
  /// Adatbázis a hívó által adott [executor]-ral (szerveren fájl, tesztben
  /// memória vagy ideiglenes fájl).
  WebDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
