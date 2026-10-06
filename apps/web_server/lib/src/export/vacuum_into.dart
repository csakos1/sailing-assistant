import 'package:drift/drift.dart';

/// A [database] konzisztens másolata a [targetPath] fájlba `VACUUM INTO`-val
/// (ADR 0050 D8). A célfájl nem létezhet; a másolat egy pillanatot rögzít,
/// a párhuzamos írás nem tör bele.
///
/// Az útvonal kötött paraméter, így idézőjel-escape nem kell. Tranzakción
/// kívül kell hívni: a `VACUUM` tranzakcióban nem fut.
Future<void> vacuumInto(DatabaseConnectionUser database, String targetPath) =>
    database.customStatement('VACUUM INTO ?', [targetPath]);
