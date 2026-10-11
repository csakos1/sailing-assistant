import 'package:domain/domain.dart';
import 'package:phone/features/race_list/race_list_entries.dart';
import 'package:phone/format/clock_format.dart';
import 'package:phone/format/month_format.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A lajstrom-sor meta-sora (makett 31a, `phone-ui-v1.md` §3).
///
/// - Folyamatban lévő versenyen az aktív bója: „2 / 4 · Tihany".
/// - Tervezett rajtnál a nap és az idő a bójaszám előtt: „MA · 09:00 ·
///   4 bója", más napon „OKT. 11. · 10:30 · 5 bója", más évben „2027.
///   JAN. 3. · …".
/// - Rajtidő nélkül csak a bójaszám: „3 bója"; bója nélkül „bója
///   nélkül" (a nulla nem darabszám, hanem üzemmód, ADR 0046 D5).
///
/// A [now] és a rajtidő a [toLocal] szerinti helyi időben számít.
String raceListMetaOf(
  AppLocalizations l10n, {
  required RaceListEntry entry,
  required DateTime now,
  required LocalWallClock toLocal,
}) {
  final race = entry.race;
  // Bója nélküli futó versenyen nincs aktív bója: ilyenkor a többi sor
  // szabálya adja a meta-sort.
  final activeMark = race.status == RaceStatus.active
      ? race.activeMarkOrNull
      : null;
  if (activeMark != null) {
    return l10n.listMetaActiveMark(
      race.activeMarkIndex + 1,
      race.marks.length,
      activeMark.name,
    );
  }
  final marks = race.marks.isEmpty
      ? l10n.listMetaNoMarks
      : l10n.listMarkCount(race.marks.length);
  final scheduledStartAt = race.scheduledStartAt;
  if (scheduledStartAt == null) return marks;
  final start = toLocal(scheduledStartAt);
  final day = entry.isToday
      ? l10n.listMetaToday
      : _dayLabel(l10n, start, today: toLocal(now));
  return [day, formatClock(start), marks].join(' · ');
}

// „OKT. 11.", más évben „2027. JAN. 3.".
String _dayLabel(
  AppLocalizations l10n,
  DateTime start, {
  required DateTime today,
}) {
  final month = monthShortName(l10n, start.month).toUpperCase();
  if (start.year == today.year) return l10n.listMetaDay(month, start.day);
  return l10n.listMetaDayWithYear(start.year, month, start.day);
}
