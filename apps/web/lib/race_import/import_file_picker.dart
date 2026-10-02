import 'package:foretack_web/race_import/picked_file.dart';

/// Egy fájl kiválasztása (ADR 0048 Addendum 4 K19). Megszakított
/// választásnál `null`.
///
/// Függvénytípus, nem egytagú absztrakt osztály (`one_member_abstracts`).
/// A böngészőben egy rejtett `<input type="file">` nyílik; a tesztek
/// előre megadott fájlt adnak.
typedef ImportFilePicker = Future<PickedFile?> Function();
