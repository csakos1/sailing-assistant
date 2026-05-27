/// Nyers (még nem dekódolt) NMEA 0183 sorok forrása — a debug raw-viewer
/// adatkönyvelő interfésze a data rétegben.
///
/// A domain `NmeaStream` szándékosan esemény-only (forrás-agnosztikus, ADR
/// 0006); a fejlesztői/diagnosztikai célú nyers sorokat ez a data-szintű,
/// külön interfész szolgálja, hogy a debug képernyő egy absztrakcióra
/// támaszkodjon, ne a konkrét osztályra (DIP). A producer (pl. a TCP kliens)
/// `implements RawNmeaLineSource`, a fogyasztó (Riverpod-réteg) ezt látja.
///
/// Egy CRLF/LF-tagolt, ELLENŐRZÉS NÉLKÜLI (a checksum nem validált) sor egy
/// elem; a stream broadcast, hogy a debug-viewer és más diagnosztika is
/// ráüljön. A szétválasztás független a parse-pipeline `utf8.decoder +
/// LineSplitter` lépéseitől — a már tesztelt pipeline ezzel érintetlen
/// marad (ADR 0006).
abstract class RawNmeaLineSource {
  /// A beérkező nyers sorok broadcast streamje.
  ///
  /// A kapcsolat-szakadás NEM zárja le — a producer egyetlen hosszú életű
  /// controllert tart, hogy a kései vagy túlélő feliratkozók a reconnecten
  /// át is megkapják a következő sorokat. A producer `dispose()`-a zárja.
  Stream<String> get rawLines;
}
