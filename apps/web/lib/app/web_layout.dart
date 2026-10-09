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

  /// A szélirány lenyíló listájának szélessége (K12).
  static const double windPointFieldWidth = 200;

  /// A szerkesztő ragadós Mentés gombjának magassága (E7).
  static const double saveButtonHeight = 58;

  /// A táblázat legnagyobb szélessége; afölött középre zárva (G2).
  static const double tableMaxWidth = 1600;

  /// A táblázat távolsága az ablak két szélétől (G2).
  static const double tableInset = 20;

  /// A táblázat csoportsorának magassága (G2).
  static const double tableGroupRowHeight = 30;

  /// A táblázat oszlopfejlécének magassága (G2).
  static const double tableHeaderRowHeight = 40;

  /// A táblázat évsorának magassága (G2).
  static const double tableYearRowHeight = 36;

  /// A táblázat egy versenysorának magassága (G2).
  static const double tableRowHeight = 40;

  /// A cellák vízszintes betéte (G2: 0 10 px).
  static const double tableCellInset = 10;

  /// A helyezés-cella számának jobbra zárt helye (G2).
  static const double tablePlaceWidth = 26;

  /// A helyezés-cella perjeles mezőnyének helye (G2).
  static const double tableFleetWidth = 34;

  /// A vízszintes görgetősáv vastagsága (G2).
  static const double tableScrollbarThickness = 8;

  /// A dobogó talapzatának vastagsága a táblázatban (G6).
  static const double tablePodiumThickness = 2;

  /// Az AppBar vezérlőinek közös magassága: a nézet-váltó és a gombok
  /// (Addendum 5 L6).
  static const double appBarControlHeight = 36;
}
