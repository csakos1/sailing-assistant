import 'package:flutter/foundation.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy napló-bejegyzés: a verseny és a napja, helyi időben.
@immutable
class LogEntry {
  /// Bejegyzés a [summary] versenyhez a [day] napon.
  const LogEntry({required this.summary, required this.day});

  /// A verseny napló-sora.
  final RaceSummary summary;

  /// A verseny napja: helyi naptári nap, éjfélkor.
  final DateTime day;
}

/// Egy hónap a naplóban, a bejegyzései a legújabbal kezdve.
@immutable
class LogMonth {
  /// A [month]-adik hónap az [entries] bejegyzésekkel.
  const LogMonth({required this.month, required this.entries});

  /// A hónap (1–12).
  final int month;

  /// A hónap versenyei, csökkenő sorrendben.
  final List<LogEntry> entries;
}

/// Egy év a naplóban, a hónapjai a legújabbal kezdve.
@immutable
class LogYear {
  /// A [year] év a [months] hónapokkal.
  const LogYear({required this.year, required this.months});

  /// Az év.
  final int year;

  /// Az év hónapjai, csökkenő sorrendben; üres hónap nincs.
  final List<LogMonth> months;

  /// Az év versenyeinek száma.
  int get raceCount =>
      months.fold(0, (count, month) => count + month.entries.length);
}

/// A [summary] verseny napja a naplóban (ADR 0048 D2 + Addendum 2 H2).
///
/// Telemetriás versenynél a hivatalos rajt, ha megvan, különben a
/// rögzítés kezdete, **helyi időben**: a böngésző Budapesten van, a
/// szerver UTC-ben fut. Kézi versenynél a naptári nap, zóna nélkül.
DateTime logDayOf(RaceSummary summary) {
  switch (summary.origin) {
    case TelemetryOrigin(:final recording):
      final instant = summary.result?.content.officialStart ?? recording.start;
      final local = instant.toLocal();
      return DateTime(local.year, local.month, local.day);
    case ManualOrigin(:final date):
      return DateTime(date.year, date.month, date.day);
  }
}

/// A napló évekre és hónapokra bontva (ADR 0048 Addendum 4 K2).
///
/// A phone `BuildRaceLog`-jának mintája, `RaceSummary`-ből. Az évek, a
/// hónapok és a bejegyzések csökkenő sorrendben jönnek. Egy napon belül a
/// bemenet sorrendje marad (a szerver a legújabbal kezd), mert a `sort`
/// nem stabil, és ezt a bemeneti index dönti el.
List<LogYear> groupRaceLog(List<RaceSummary> summaries) {
  final entries =
      [
        for (final (index, summary) in summaries.indexed)
          (
            index: index,
            entry: LogEntry(summary: summary, day: logDayOf(summary)),
          ),
      ]..sort((a, b) {
        final byDay = b.entry.day.compareTo(a.entry.day);
        return byDay != 0 ? byDay : a.index.compareTo(b.index);
      });

  final byYear = <int, Map<int, List<LogEntry>>>{};
  for (final (:entry, index: _) in entries) {
    byYear
        .putIfAbsent(entry.day.year, () => <int, List<LogEntry>>{})
        .putIfAbsent(entry.day.month, () => <LogEntry>[])
        .add(entry);
  }

  // A map a beszúrás sorrendjét őrzi, és a bejegyzések már rendezettek:
  // az évek és a hónapok így csökkenő sorrendben jönnek.
  return List.unmodifiable([
    for (final MapEntry(key: year, value: months) in byYear.entries)
      LogYear(
        year: year,
        months: List.unmodifiable([
          for (final MapEntry(key: month, value: monthEntries)
              in months.entries)
            LogMonth(month: month, entries: List.unmodifiable(monthEntries)),
        ]),
      ),
  ]);
}
