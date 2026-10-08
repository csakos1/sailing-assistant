import 'package:phone/features/web_access/presentation/join_formatters.dart';
import 'package:phone/l10n/app_localizations.dart';

// A kezelőképernyők idő-, hely- és böngésző-szövegei (ADR 0051 Addendum
// 10 Z8). Pure függvények a [now] pillanathoz képest, a telefon helyi
// idejében, hogy teszt-órával ellenőrizhetők legyenek.

/// Egy időpont: „ma 09:12", „tegnap 21:40", az idei évben „okt. 3.",
/// korábban „2025. aug. 30.".
String formatWebMoment(AppLocalizations l10n, DateTime moment, DateTime now) {
  final local = moment.toLocal();
  final day = _dayOf(local);
  final today = _dayOf(now.toLocal());
  if (day == today) return l10n.webTimeToday(formatLocalClock(local));
  if (day == _previousDay(today)) {
    return l10n.webTimeYesterday(formatLocalClock(local));
  }
  final month = monthShortName(l10n, local.month);
  if (local.year == today.year) return l10n.webTimeThisYear(month, local.day);
  return l10n.webTimeOlder(local.year, month, local.day);
}

/// A szalag időpontja: ma csak „14:32", egyébként mint a
/// [formatWebMoment] (makett 18h-2).
String formatBannerMoment(
  AppLocalizations l10n,
  DateTime moment,
  DateTime now,
) {
  final local = moment.toLocal();
  return _dayOf(local) == _dayOf(now.toLocal())
      ? formatLocalClock(local)
      : formatWebMoment(l10n, moment, now);
}

/// Az eltelt idő a [moment] óta: „most", „N perce", „N órája", „N napja",
/// lefelé kerekítve. Egy jövőbeli pillanat (eltérő órák) „most".
String formatWebAgo(AppLocalizations l10n, DateTime moment, DateTime now) {
  final elapsed = now.difference(moment);
  if (elapsed.inMinutes < 1) return l10n.webAgoNow;
  if (elapsed.inHours < 1) return l10n.webAgoMinutes(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l10n.webAgoHours(elapsed.inHours);
  return l10n.webAgoDays(elapsed.inDays);
}

/// A [month] (1–12) rövid neve az ARB listájából.
String monthShortName(AppLocalizations l10n, int month) =>
    l10n.webMonthsShort.split('|')[month - 1];

/// A hely: „Budapest, HU", csak ország „HU", semmi esetén `null`.
String? placeOf({String? city, String? country}) {
  final parts = [?city, ?country];
  return parts.isEmpty ? null : parts.join(', ');
}

/// A böngésző és az OS „·"-tal; ha egyik sem ismert, „Ismeretlen
/// böngésző".
String browserLineOf(
  AppLocalizations l10n, {
  String? browser,
  String? os,
}) {
  final parts = [?browser, ?os];
  return parts.isEmpty ? l10n.webUnknownBrowser : parts.join(' · ');
}

typedef _Day = ({int year, int month, int day});

_Day _dayOf(DateTime local) =>
    (year: local.year, month: local.month, day: local.day);

// A naptári előző nap; a `DateTime` a hónap- és évhatárt is átviszi.
_Day _previousDay(_Day day) =>
    _dayOf(DateTime(day.year, day.month, day.day - 1));
