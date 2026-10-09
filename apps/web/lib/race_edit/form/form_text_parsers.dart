// Az űrlap szövegeinek olvasása és visszaírása (ADR 0048 Addendum 4 K11).
// Pure függvények: a mező szövegéből érték lesz, vagy a várt alak. Az üres
// (csak szóközös) szöveg mindenhol „nincs megadva", nem hiba.

import 'package:foretack_web/race_edit/form/clock_time.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Egy pozitív egész, pl. helyezés vagy mezőny.
///
/// Csak számjegyet fogad el, legfeljebb hat jegyet: egy ennél hosszabb
/// helyezés elírás, nem adat.
Result<int?, TextFormat> parseWholeNumber(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const Ok(null);
  if (!_wholeNumberPattern.hasMatch(trimmed)) {
    return const Err(TextFormat.wholeNumber);
  }
  return Ok(int.parse(trimmed));
}

/// Egy nem negatív tizedes szám vesszővel vagy ponttal, pl. `10,2`.
Result<double?, TextFormat> parseDecimal(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const Ok(null);
  if (!_decimalPattern.hasMatch(trimmed)) {
    return const Err(TextFormat.decimalNumber);
  }
  return Ok(double.parse(trimmed.replaceAll(',', '.')));
}

/// A YS-szám századokban: `75,90` vagy `75.90` → 7590.
///
/// Pontosan két tizedes kell (Addendum 1 G4): a `75,9` kétértelmű lehet
/// egy elgépelt `75,95`-tel, ezért nem egészítjük ki.
Result<int?, TextFormat> parseYsNumber(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const Ok(null);
  final match = _ysPattern.firstMatch(trimmed);
  if (match == null) return const Err(TextFormat.ysNumber);
  // A `!` biztonságos: a minta mindkét csoportja kötelező.
  final whole = int.parse(match.group(1)!);
  final hundredths = int.parse(match.group(2)!);
  return Ok(whole * 100 + hundredths);
}

/// Egy naptári nap: `2026.06.13`, `2026.6.13.`, `2026-06-13` vagy
/// `20260613`. A nem létező nap (pl. `2026.02.30`) hiba.
Result<CalendarDate?, TextFormat> parseFormDate(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const Ok(null);
  final match =
      _separatedDatePattern.firstMatch(trimmed) ??
      _compactDatePattern.firstMatch(trimmed);
  if (match == null) return const Err(TextFormat.date);
  // A `!` biztonságos: mindkét minta mindhárom csoportja kötelező.
  final date = CalendarDate.tryFromParts(
    year: int.parse(match.group(1)!),
    month: int.parse(match.group(2)!),
    day: int.parse(match.group(3)!),
  );
  return date == null ? const Err(TextFormat.date) : Ok(date);
}

/// Egy óra:perc(:másodperc) idő: `10:00`, `9:05`, `10:00:30`, vagy csak
/// számjegyek: `9` → 09:00, `930` → 09:30, `1000` → 10:00.
Result<ClockTime?, TextFormat> parseClockTime(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const Ok(null);
  final parts = _clockParts(trimmed);
  if (parts == null) return const Err(TextFormat.time);
  final (hour, minute, second) = parts;
  if (hour > 23 || minute > 59 || second > 59) {
    return const Err(TextFormat.time);
  }
  return Ok((hour: hour, minute: minute, second: second));
}

/// Egy nap az űrlap alakjában: `2026.06.13`.
String formatFormDate(CalendarDate date) =>
    '${date.year.toString().padLeft(4, '0')}.'
    '${_twoDigits(date.month)}.${_twoDigits(date.day)}';

/// Egy idő az űrlap alakjában: `09:30`, másodperccel `09:30:15`.
String formatClockTime(ClockTime time) {
  final minutes = '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
  return time.second == 0 ? minutes : '$minutes:${_twoDigits(time.second)}';
}

/// Egy tizedes szám az űrlap alakjában, vesszővel, legfeljebb
/// [fractionDigits] tizedesre, a fölösleges nullák nélkül: `10,2`, `8`.
String formatFormDecimal(double value, {int fractionDigits = 1}) {
  final fixed = value.toStringAsFixed(fractionDigits);
  final trimmed = fixed.contains('.')
      ? fixed.replaceFirst(RegExp(r'\.?0+$'), '')
      : fixed;
  return trimmed.replaceAll('.', ',');
}

(int, int, int)? _clockParts(String text) {
  final colon = _colonTimePattern.firstMatch(text);
  if (colon != null) {
    // A `!` biztonságos: az óra és a perc csoportja kötelező.
    return (
      int.parse(colon.group(1)!),
      int.parse(colon.group(2)!),
      int.parse(colon.group(3) ?? '0'),
    );
  }
  if (!_digitsOnlyPattern.hasMatch(text)) return null;
  // Csak számjegy: 1–2 jegy óra, 3–4 jegy óra + perc (az utolsó kettő a
  // perc), 5–6 jegy óra + perc + másodperc.
  return switch (text.length) {
    1 || 2 => (int.parse(text), 0, 0),
    3 || 4 => (
      int.parse(text.substring(0, text.length - 2)),
      int.parse(text.substring(text.length - 2)),
      0,
    ),
    5 || 6 => (
      int.parse(text.substring(0, text.length - 4)),
      int.parse(text.substring(text.length - 4, text.length - 2)),
      int.parse(text.substring(text.length - 2)),
    ),
    _ => null,
  };
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

final RegExp _wholeNumberPattern = RegExp(r'^\d{1,6}$');
final RegExp _decimalPattern = RegExp(r'^\d{1,6}([.,]\d+)?$');
final RegExp _ysPattern = RegExp(r'^(\d{1,3})[.,](\d{2})$');
final RegExp _separatedDatePattern = RegExp(
  r'^(\d{4})[.\-/](\d{1,2})[.\-/](\d{1,2})\.?$',
);
final RegExp _compactDatePattern = RegExp(r'^(\d{4})(\d{2})(\d{2})$');
final RegExp _colonTimePattern = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$');
final RegExp _digitsOnlyPattern = RegExp(r'^\d+$');
