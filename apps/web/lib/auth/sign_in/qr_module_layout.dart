/// A QR-kép modul-rácsa egy négyzetben (ADR 0051 Addendum 7 P6): a modul
/// oldala és a rács bal felső sarkának távolsága a négyzet szélétől.
typedef QrModuleLayout = ({double moduleSize, double offset});

/// A [moduleCount] modulos kód rácsa egy [extent] oldalú négyzetben,
/// legalább [quietZone] csendes zónával.
///
/// A modul egész pixel: a szkennernek éles, egyforma modulok kellenek. A
/// lefelé kerekítés maradéka a csendes zónához adódik, a rács középre
/// kerül, és a kezdőpontja is egész pixel.
QrModuleLayout qrModuleLayout({
  required double extent,
  required int moduleCount,
  required double quietZone,
}) {
  assert(moduleCount > 0, 'A QR-kódnak van modulja.');
  final moduleSize = ((extent - 2 * quietZone) / moduleCount).floorToDouble();
  final offset = ((extent - moduleSize * moduleCount) / 2).floorToDouble();
  return (moduleSize: moduleSize, offset: offset);
}
