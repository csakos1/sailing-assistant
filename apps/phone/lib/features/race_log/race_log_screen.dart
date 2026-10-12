import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_detail/race_detail_screen.dart';
import 'package:phone/features/race_log/widgets/race_log_empty.dart';
import 'package:phone/features/race_log/widgets/race_log_loading_list.dart';
import 'package:phone/features/race_log/widgets/race_log_year_band.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/race_log_provider.dart';
import 'package:phone/providers/race_log_stats_provider.dart';
import 'package:phone/providers/race_log_year_provider.dart';

/// A befejezett versenyek naplója (ADR 0044 4d), a héj Versenynapló füle
/// (ADR 0056 D2, D4; makett 35a, 35f).
///
/// A fejrész a Versenyek füléével azonos (64 dp, `tabTitleStyle`, alsó
/// hairline), jobb oldalán a kiválasztott év versenyszámával (UF). Alatta
/// az évsáv a webes 7c mintájára: maga az évsor a választó, alatta a
/// kiválasztott év három statja. A képernyőn nincs év-független szám: amit
/// a felhasználó lát, az a kiválasztott évhez tartozik (D38). A
/// hónap-fejlécek és a sorok a mai napló szerint (felhasználói döntés, U8).
///
/// A három stat **nem egyszerre érkezik** (D42). A vízen töltött idő
/// szinkron, a naplóval együtt már megvan; az össztáv és a rekord a
/// track-mintákból számol. Amíg számolódik, a két érték tompa hiányjel, és
/// a sáv alján mozgó sáv fut (makett 35f). A teljes napló betöltése alatt
/// a lista helyén a sorok vázai állnak.
///
/// Nincs új lekérdezés a lista felé (D41): a napló a lajstroméval azonos
/// reaktív projekcióból épül, a csoportosítást a `BuildRaceLog` domain use
/// case végzi.
///
/// Az `AppLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class RaceLogScreen extends ConsumerWidget {
  /// A Versenynapló képernyője; paramétert nem vesz át, mindent providerből
  /// olvas.
  const RaceLogScreen({super.key});

  // A számolás alatti stat-érték (makett 35f); a mértékegység a valódi
  // formázóé, hogy a kettő ne térhessen el.
  static const String _pendingValue = '––,–';

  void _openDetail(BuildContext context, Race race) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RaceDetailScreen(race: race),
        ),
      ),
    );
  }

  // Számolás alatt csak a mértékegység ismert. Egy hiányzó mérés
  // formázása mértékegység nélküli, ezért a mértékegységet egy minta-érték
  // formázásából vesszük.
  static final MeasuredValue _timeSample = measureHours(
    const Duration(hours: 1),
  );
  static final MeasuredValue _distanceSample = measureDistance(1000);
  static final MeasuredValue _speedSample = measureKnots(1);

  static RaceLogBandStat _stat(
    String label,
    MeasuredValue measured,
  ) => (label: label, measured: measured, isPending: false);

  static RaceLogBandStat _pendingStat(String label, MeasuredValue sample) => (
    label: label,
    measured: (value: _pendingValue, unit: sample.unit),
    isPending: true,
  );

  static List<RaceLogBandStat> _pendingStats(AppLocalizations l10n) => [
    _pendingStat(l10n.logStatTimeCaps, _timeSample),
    _pendingStat(l10n.logStatDistanceCaps, _distanceSample),
    _pendingStat(l10n.logStatRecordCaps, _speedSample),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final log = ref.watch(raceLogProvider);
    final selected = ref.watch(raceLogSelectedYearProvider);
    final timeOnWater = ref.watch(raceLogTimeOnWaterProvider);
    final totalsAsync = ref.watch(raceLogTrackTotalsProvider);
    // Évváltáskor a provider az előző év értékével tölt újra: azt nem
    // mutatjuk az új év alatt (D38), hanem a számolás jelét.
    final isTotalsPending = totalsAsync.isLoading;
    final totals = isTotalsPending ? null : totalsAsync.valueOrNull;
    // A versenyszám a fejrészben (UF), a törzzsel azonos állapot szerint:
    // töltés alatt hiányjellel, üres naplónál és hibánál nincs.
    final countLabel = log.when<String?>(
      loading: () => l10n.logRaceCountPendingCaps,
      error: (_, _) => null,
      data: (_) =>
          selected == null ? null : l10n.logRaceCountCaps(selected.raceCount),
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 20,
        // Görgetéskor az M3 AppBar `surfaceContainer`-re váltana; a fejrész
        // színe a listától független marad (UF, felhasználói döntés).
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        title: Text(l10n.logTitle, style: tabTitleStyle),
        actions: [
          if (countLabel != null)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Text(
                  countLabel,
                  style: numeralCaptionStyle.copyWith(color: tones.low),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: log.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RaceLogYearBand(
                years: const [],
                selectedYear: null,
                stats: _pendingStats(l10n),
                isLoading: true,
              ),
              const Expanded(child: RaceLogLoadingList()),
            ],
          ),
          error: (_, _) => Center(child: Text(l10n.listError)),
          data: (years) {
            if (selected == null) {
              return ListView(
                padding: EdgeInsets.zero,
                children: const [RaceLogEmpty()],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RaceLogYearBand(
                  years: [for (final year in years) year.year],
                  selectedYear: selected.year,
                  onYearSelected: (year) {
                    ref.read(raceLogYearSelectionProvider.notifier).state =
                        year;
                  },
                  isLoading: isTotalsPending,
                  stats: [
                    _stat(l10n.logStatTimeCaps, measureHours(timeOnWater)),
                    if (isTotalsPending) ...[
                      _pendingStat(l10n.logStatDistanceCaps, _distanceSample),
                      _pendingStat(l10n.logStatRecordCaps, _speedSample),
                    ] else ...[
                      _stat(
                        l10n.logStatDistanceCaps,
                        measureDistance(totals?.distanceMeters),
                      ),
                      _stat(
                        l10n.logStatRecordCaps,
                        measureKnots(totals?.maxSpeedMps),
                      ),
                    ],
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
