/// A napló két nézete (ADR 0048 Addendum 1 G1, Addendum 4 K26).
enum LogViewMode {
  /// A hónapokra bontott lista, a phone sorával.
  list,

  /// Az Excel-szerű táblázat, versenyenként egy sorral.
  table,
}
