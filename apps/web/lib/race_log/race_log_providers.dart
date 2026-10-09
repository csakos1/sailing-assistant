import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/app/api_providers.dart';
import 'package:foretack_web/race_log/log_period.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:foretack_web/race_log/race_log_view.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A napló sorai a szerverről (ADR 0048 Addendum 4 K2).
///
/// A hiba az `ApiFailure`, dobva: a `FutureProvider` így viszi az
/// `AsyncValue.error`-ba. Az ÚJRA gomb ezt a providert érvényteleníti.
final FutureProvider<List<RaceSummary>> raceSummariesProvider =
    FutureProvider<List<RaceSummary>>((ref) async {
      final result = await ref
          .watch(archiveApiClientProvider)
          .fetchRaceSummaries();
      return switch (result) {
        Ok(:final value) => value,
        Err(:final error) => throw error,
      };
    });

/// A napló választott időszaka (ADR 0048 Addendum 4 K2).
///
/// Nem `autoDispose`: a munkameneten belül megmarad, és a Lista meg a
/// Táblázat nézet közösen használja (14w).
final NotifierProvider<LogPeriodNotifier, LogPeriod> logPeriodProvider =
    NotifierProvider<LogPeriodNotifier, LogPeriod>(LogPeriodNotifier.new);

/// A [logPeriodProvider] állapota és műveletei.
class LogPeriodNotifier extends Notifier<LogPeriod> {
  @override
  LogPeriod build() => const NewestYear();

  /// A [year] év kiválasztása.
  void chooseYear(int year) => state = ChosenYear(year);

  /// Az összes év kiválasztása.
  void chooseAllYears() => state = const AllYears();
}

/// A napló képernyőjének állapota: betöltés, hiba, vagy a kész nézet.
///
/// A csoportosítás és az összesítés pure függvény (`groupRaceLog`,
/// `buildRaceLogView`); ez a provider csak összeköti őket az adattal és a
/// választással.
final Provider<AsyncValue<RaceLogView>> raceLogViewProvider =
    Provider<AsyncValue<RaceLogView>>((ref) {
      final period = ref.watch(logPeriodProvider);
      return ref
          .watch(raceSummariesProvider)
          .whenData(
            (summaries) => buildRaceLogView(groupRaceLog(summaries), period),
          );
    });
