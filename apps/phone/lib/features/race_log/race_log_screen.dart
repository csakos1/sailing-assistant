import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/features/race_detail/race_detail_screen.dart';
import 'package:phone/features/race_detail/track_stats_formatters.dart';
import 'package:phone/features/race_log/race_log_formatters.dart';
import 'package:phone/features/race_log/widgets/race_log_month_header.dart';
import 'package:phone/features/race_log/widgets/race_log_row.dart';
import 'package:phone/features/race_log/widgets/race_log_stats_strip.dart';
import 'package:phone/features/race_log/widgets/race_log_year_bar.dart';
import 'package:phone/features/race_log/widgets/race_log_year_sheet.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/race_log_provider.dart';
import 'package:phone/providers/race_log_stats_provider.dart';
import 'package:phone/providers/race_log_year_provider.dart';

/// A befejezett versenyek naplója (ADR 0044 4d).
///
/// Önálló képernyő, nem modal (D31): az alsó akció-sáv bal feléről nyílik,
/// `MaterialPageRoute`-tal. A fejléc 64 dp-s, mint a detail-képernyőé, alatta
/// a 44 dp-s év-sáv — a két mély képernyő felső harmada így egymásra fed
/// (D20/D21).
///
/// A tartalom négy rétegű: az AppBar jobb szélén a **kiválasztott év**
/// verseny-száma, alatta a mindig látható év-sáv, majd az összesítő
/// stat-csík, végül a hónapokra bontott lista. A képernyőn nincs
/// év-független szám: amit a felhasználó lát, az a sáv által mutatott évhez
/// tartozik (D38).
///
/// A csík három értéke **nem egyszerre érkezik** (D42). A vízen töltött idő
/// szinkron, a naplóval együtt már megvan; az össztáv és a rekord a
/// track-mintákból számol, és a saját `AsyncValue`-ja mögül úszik be. Amíg
/// nincs kész, a két cella a hiányjelet mutatja — a betöltés és a hiányzó
/// mérés így egyformán néz ki, ami tudatos egyszerűsítés: cellánkénti
/// spinner zajosabb lenne. Ha a mérés hosszúnak mutatja a beúszást, ezen
/// érdemes változtatni.
///
/// Nincs új lekérdezés a lista felé (D41): a napló a lajstroméval azonos
/// reaktív projekcióból épül, a csoportosítást a `BuildRaceLog` domain use
/// case végzi.
///
/// Az `AppLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat. A `TextTones` ugyanígy: a `foretackTheme`
/// regisztrálja.
class RaceLogScreen extends ConsumerWidget {
  /// A Versenynapló képernyője; paramétert nem vesz át, mindent providerből
  /// olvas.
  const RaceLogScreen({super.key});

  // Az év-választó lapot nyitja, és a választást a nyers state-be írja. A
  // feloldást (elavult év, alapértelmezés) a selected-provider végzi.
  Future<void> _pickYear(
    BuildContext context,
    WidgetRef ref, {
    required List<RaceLogYear> years,
    required int selectedYear,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => RaceLogYearSheet(
        title: l10n.logYearSheetTitle,
        years: years,
        selectedYear: selectedYear,
      ),
    );
    if (picked == null) return;
    ref.read(raceLogYearSelectionProvider.notifier).state = picked;
  }

  void _openDetail(BuildContext context, Race race) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RaceDetailScreen(race: race),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tones = Theme.of(context).extension<TextTones>()!;
    final log = ref.watch(raceLogProvider);
    final selected = ref.watch(raceLogSelectedYearProvider);
    final timeOnWater = ref.watch(raceLogTimeOnWaterProvider);
    final totals = ref.watch(raceLogTrackTotalsProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        // A kulcs az S10-ben nevet valt logTitle-re; addig a mai felirat
        // marad, hogy a branch minden szeleten zold legyen.
        title: Text(l10n.listFinishedRacesTitle, style: screenTitleStyle),
        actions: [
          if (selected != null)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Text(
                  l10n.logRaceCountCaps(selected.raceCount),
                  style: numeralCaptionStyle.copyWith(color: tones.low),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: log.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.listError)),
          data: (years) {
            // Üres naplóval a képernyő el sem érhető (a belépő gomb
            // letiltva), ezért itt nem üzenünk, csak nem rajzolunk.
            if (selected == null) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RaceLogYearBar(
                  year: selected.year,
                  onTap: () => unawaited(
                    _pickYear(
                      context,
                      ref,
                      years: years,
                      selectedYear: selected.year,
                    ),
                  ),
                ),
                RaceLogStatsStrip(
                  cells: [
                    (
                      label: l10n.logStatTimeCaps,
                      measured: measureHours(timeOnWater),
                    ),
                    (
                      label: l10n.logStatDistanceCaps,
                      measured: measureDistance(totals?.distanceMeters),
                    ),
                    (
                      label: l10n.logStatRecordCaps,
                      measured: measureKnots(totals?.maxSpeedMps),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final month in selected.months) ...[
                        RaceLogMonthHeader(
                          monthLabel: l10n.logMonth(
                            DateTime(selected.year, month.month),
                          ),
                          countLabel: l10n.logRaceCountCaps(month.raceCount),
                        ),
                        for (final race in month.races)
                          RaceLogRow(
                            race: race,
                            onTap: () => _openDetail(context, race),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
