/// A web makettjének nem-token méretei (ADR 0047 Addendum 4 E3).
///
/// Egyetlen fogyasztójuk a web, ezért itt élnek, nem a `foretack_ui`-ban.
/// Ha egy érték közös widgetbe kerül, az a widget saját konstansa lesz.
abstract final class WebLayout {
  /// A tartalom-oszlop legnagyobb szélessége; keskenyebb ablakban kitölti.
  static const double columnMaxWidth = 880;

  /// Az AppBar magassága.
  static const double appBarHeight = 64;

  /// A tartalom bal és jobb betéte az oszlopon belül.
  static const double columnInset = 20;

  /// A hosszú szöveg (összefoglaló, űrlap) legnagyobb szélessége.
  static const double textMaxWidth = 640;

  /// A részletező térkép-kártyájának magassága (E4: 880×560).
  static const double mapHeight = 560;

  /// A `ForetackDialog` szélessége a weben (ADR 0047 E6, Addendum 1 G5).
  static const double dialogWidth = 480;

  /// A snackbar szélessége (G5, K17).
  static const double snackBarWidth = 480;

  /// A snackbar távolsága az ablak aljától (G5).
  static const double snackBarBottomGap = 24;

  /// A szerkesztő bal címke-oszlopa (G4).
  static const double editorLabelWidth = 132;

  /// A szerkesztő mezőinek és szegmens-celláinak magassága (G4).
  static const double editorFieldHeight = 54;

  /// A helyezés- és a mezőny-mező szélessége (G4, E7).
  static const double placingFieldWidth = 104;

  /// A dátummező szélessége (G4).
  static const double dateFieldWidth = 144;

  /// Az időmező szélessége (G4).
  static const double timeFieldWidth = 120;

  /// A szerkesztő ragadós Mentés gombjának magassága (E7).
  static const double saveButtonHeight = 58;
}
