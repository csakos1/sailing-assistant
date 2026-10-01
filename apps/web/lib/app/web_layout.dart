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
}
