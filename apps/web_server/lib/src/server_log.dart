/// A szerver naplósora: egy ember által olvasható üzenet.
///
/// Függvény, nem logger-osztály: a `bin` a stderr-re köti, a teszt egy
/// listába gyűjti. Így a naplózás külső függőség nélkül cserélhető.
typedef ServerLog = void Function(String message);

/// Néma napló: ahol a hívó nem kér naplózást (például a CLI-import).
void ignoreServerLog(String message) {}
