import 'package:meta/meta.dart';

/// Egy checksum-validált, de még nem értelmezett NMEA 0183 mondat.
///
/// A `Nmea0183LineParser` állítja elő: a `$`/`!` és `*` közti payloadot
/// vesszők mentén bontja; az első token adja a [talker]+[type] párost, a
/// maradék a [fields]. A mezők nyers stringek — a tipizálás (szög,
/// sebesség, koordináta) a mondat-dekóderek dolga (ARCHITECTURE.md 6.4).
@immutable
class Sentence {
  /// Nyers mondatot csomagol. A [fields] már az address-token nélküli
  /// adatmezőket tartalmazza (az address-token a [talker]+[type]).
  const Sentence({
    required this.talker,
    required this.type,
    required this.fields,
    required this.raw,
  });

  /// A talker azonosító — az address-token első két karaktere (pl. `WI`).
  final String talker;

  /// A mondat típusa — az address-token többi karaktere (pl. `MWV`).
  final String type;

  /// A `*` előtti adatmezők, az address-token nélkül (nyers stringek).
  final List<String> fields;

  /// A teljes eredeti sor (debug/log célra).
  final String raw;
}
