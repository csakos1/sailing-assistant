import 'package:equatable/equatable.dart';

/// Egy naptári nap időzóna nélkül (ADR 0048 Addendum 2 H2).
///
/// A kézi verseny napja: nincs hozzá pillanat, csak év, hónap és nap. Ezért
/// nem `DateTime`, amely mindig egy pillanatot és egy zónát hordoz, és
/// zónák közt átváltva másik napra csúszhatna. Dróton `"YYYY-MM-DD"`.
final class CalendarDate extends Equatable implements Comparable<CalendarDate> {
  const CalendarDate._(this.year, this.month, this.day);

  /// A `"YYYY-MM-DD"` alakú [text] naptári napja, vagy `null`, ha az alak
  /// rossz, vagy a nap nem létezik (pl. `2026-02-30`).
  static CalendarDate? tryParse(String text) {
    final match = _isoPattern.firstMatch(text);
    if (match == null) return null;
    return tryFromParts(
      year: int.parse(match.group(1)!),
      month: int.parse(match.group(2)!),
      day: int.parse(match.group(3)!),
    );
  }

  /// A megadott nap, vagy `null`, ha nem létezik. Az év 1 és 9999 közé
  /// esik, hogy a `"YYYY-MM-DD"` alak mindig négy jegyű évet adjon.
  static CalendarDate? tryFromParts({
    required int year,
    required int month,
    required int day,
  }) {
    if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1) {
      return null;
    }
    // A DateTime a túlcsorduló napot a következő hónapra görgeti; ha a
    // visszaolvasott hónap eltér, a nap nem létezik.
    final probe = DateTime.utc(year, month, day);
    if (probe.month != month || probe.day != day) return null;
    return CalendarDate._(year, month, day);
  }

  // A `!` biztonságos a [tryParse]-ban: a minta mindhárom csoportja
  // kötelező, így egyezésnél egyik sem `null`.
  static final RegExp _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Év (1–9999).
  final int year;

  /// Hónap (1–12).
  final int month;

  /// A hónap napja (1–31).
  final int day;

  /// `"YYYY-MM-DD"` alak, a dróton és a `web.sqlite`-ban is.
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(CalendarDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  List<Object?> get props => [year, month, day];

  @override
  String toString() => 'CalendarDate(${toIso()})';
}
