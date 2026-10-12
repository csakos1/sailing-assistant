import 'package:phone/format/clock_format.dart';
import 'package:phone/format/month_format.dart';
import 'package:phone/l10n/app_localizations.dart';

/// Egy verseny napja verzál rövid alakban: „OKT. 11.", más évben
/// „2027. JAN. 3.".
///
/// Helyi időt vár ([localStart], [localToday]): a hívó a `localWallClock`
/// után adja. A lajstrom meta-sora és a részlet csíkja közösen használja,
/// hogy a kettő ugyanazt a napot ugyanúgy írja.
String formatRaceDate(
  AppLocalizations l10n,
  DateTime localStart, {
  required DateTime localToday,
}) {
  final month = monthShortName(l10n, localStart.month).toUpperCase();
  if (localStart.year == localToday.year) {
    return l10n.listMetaDay(month, localStart.day);
  }
  return l10n.listMetaDayWithYear(localStart.year, month, localStart.day);
}

/// Mint a [formatRaceDate], de a mai napra „MA".
String formatRaceDay(
  AppLocalizations l10n,
  DateTime localStart, {
  required DateTime localToday,
}) {
  if (_isSameDay(localStart, localToday)) return l10n.listMetaToday;
  return formatRaceDate(l10n, localStart, localToday: localToday);
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Egy tervezett rajt rövid alakban: a mai napon csak az idő („09:00"),
/// más napon a nap is („OKT. 13. 09:00").
///
/// A részlet „AUTOMATIKUS" cellája és a rajt-dialógus használja, hogy egy
/// holnapi rajt ne olvasódjon mainak.
String formatRaceStart(
  AppLocalizations l10n,
  DateTime localStart, {
  required DateTime localToday,
}) {
  final clock = formatClock(localStart);
  if (_isSameDay(localStart, localToday)) return clock;
  return '${formatRaceDate(l10n, localStart, localToday: localToday)} $clock';
}
