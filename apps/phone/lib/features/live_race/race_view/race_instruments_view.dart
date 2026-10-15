import 'dart:async';
import 'dart:developer' as developer;

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// A `foretack_ui` track-stat `formatDistance`-e méterben számol, a Műszerek
// fülé a `live_formatters` `Distance`-alapú változata.
import 'package:foretack_ui/foretack_ui.dart' hide formatDistance;
import 'package:phone/app/true_time.dart';
import 'package:phone/features/live_race/free_mode/free_mode_link.dart';
import 'package:phone/features/live_race/instruments_link_provider.dart';
import 'package:phone/features/live_race/instruments_race_chooser_provider.dart';
import 'package:phone/features/live_race/live_formatters.dart';
import 'package:phone/features/live_race/race_view/race_strip_title.dart';
import 'package:phone/features/live_race/race_view/today_races_menu.dart';
import 'package:phone/features/live_race/target_speed.dart';
import 'package:phone/features/live_race/today_races_provider.dart';
import 'package:phone/features/live_race/widgets/correction_value.dart';
import 'package:phone/features/live_race/widgets/data_rail.dart';
import 'package:phone/features/live_race/widgets/instruments_strip.dart';
import 'package:phone/features/live_race/widgets/main_column_cell.dart';
import 'package:phone/features/live_race/widgets/predicted_twa_cell.dart';
import 'package:phone/features/live_race/widgets/rail_cell.dart';
import 'package:phone/features/live_race/widgets/side_arrow.dart';
import 'package:phone/features/live_race/widgets/twa_value.dart';
import 'package:phone/features/live_race/widgets/warning_banner.dart';
import 'package:phone/features/safety_map/safety_map_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/active_warnings_provider.dart';
import 'package:phone/providers/engine_service_error_provider.dart';
import 'package:phone/providers/engine_session_provider.dart';
import 'package:phone/providers/engine_session_state.dart';
import 'package:phone/providers/gps_time_reading_provider.dart';
import 'package:phone/providers/local_wall_clock_provider.dart';
import 'package:phone/providers/mark_prediction_provider.dart';
import 'package:phone/providers/race_engine_host_provider.dart';
import 'package:phone/providers/race_snapshot_provider.dart';
import 'package:phone/providers/twd_quality_provider.dart';
import 'package:phone/providers/wind_data_provider.dart';

/// A Műszerek fül rajt előtti (34b) és versenyes (34c) tartalma (ADR 0056
/// D3, U4): az 1c váza (ADR 0042) a közös csíkkal és a BEARING helyén a
/// sebességgel.
///
/// Rajt előtt ([isPreStart]) az engine a rajthelyre vezet (ADR 0055 D2): a
/// csíkban csak a versenynév (több mai versenynél a váltó), lent a „Rajt
/// most". Versenyen a csíkban a név és a cél-bója, lent a „Bója megvan".
/// Mindkettő megerősítést kér.
///
/// A kijelző ébren tartását a `LiveRaceScreen` intézi a tartalom szerint.
class RaceInstrumentsView extends ConsumerStatefulWidget {
  /// A [race] nézete; az [isPreStart] dönt a 34b és a 34c között.
  const RaceInstrumentsView({
    required this.race,
    required this.isPreStart,
    super.key,
  });

  /// Az engine versenye.
  final Race race;

  /// Rajt előtti nézet (34b); különben verseny (34c).
  final bool isPreStart;

  @override
  ConsumerState<RaceInstrumentsView> createState() =>
      _RaceInstrumentsViewState();
}

class _RaceInstrumentsViewState extends ConsumerState<RaceInstrumentsView> {
  // Megszakadt kapcsolatnál az utolsó értékek ennyire tompulnak, mint a
  // szabad módban (34a-3).
  static const double _lostOpacity = 0.42;

  // Kritikus warningnál a rács tompítása (ADR 0014 D6).
  static const double _criticalOpacity = 0.4;

  /// Az alsó akció-sáv magassága (`phone-ui-v1.md` §6: 56 dp).
  static const double actionBarHeight = 56;

  // A felirat mérete a sáv magasságából (ADR 0042 Addendum 2).
  static const double _actionLabelSize = actionBarHeight * 0.3;

  bool _isSwitcherOpen = false;

  @override
  void didUpdateWidget(RaceInstrumentsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rajt után nincs mit váltani: a lista ne maradjon nyitva a 34c-n.
    if (!widget.isPreStart) _isSwitcherOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    // Az `AppLocalizations` a `MaterialApp` alatt mindig jelen van.
    final l10n = AppLocalizations.of(context)!;
    final race = widget.race;
    final prediction = ref.watch(markPredictionProvider);
    final snapshot = ref.watch(raceSnapshotProvider);
    final session = ref.watch(engineSessionProvider);
    final (:link, :isStale) = ref.watch(instrumentsLinkProvider);
    final gpsTime =
        ref.watch(gpsTimeReadingProvider).valueOrNull ??
        const TrueTimeReading(utc: null, source: TrueTimeSource.none);
    final warnings = ref.watch(activeWarningsProvider);
    final serviceError = ref.watch(engineServiceErrorProvider);
    final todayRaces = widget.isPreStart
        ? ref.watch(todayRacesProvider)
        : const <Race>[];
    final isSwitchable =
        todayRaces.length > 1 && todayRaces.any((today) => today.id == race.id);
    // Ha közben nincs mit váltani (pl. lejárt egy ablak), a lista zárva
    // marad, és később sem nyílik ki magától.
    if (!isSwitchable) _isSwitcherOpen = false;
    final hasCriticalWarning = warnings.any(
      (warning) => warning.severity == WarningSeverity.critical,
    );
    // A kisebbik nyer: a kritikus warning tompítása a nagyobb.
    final gridOpacity = hasCriticalWarning
        ? _criticalOpacity
        : link is FreeModeLost
        ? _lostOpacity
        : 1.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            InstrumentsStrip(
              link: link,
              trueTime: gpsTime,
              isStale: isStale,
              title: RaceStripTitle(
                raceName: race.name,
                // Rajt előtt csak a név (34b); versenyen a cél-bója a
                // léptetett predikcióból, különben a verseny aktív bójája.
                markName: widget.isPreStart
                    ? null
                    : prediction?.mark.name ?? race.guidanceTargetOrNull?.name,
                switchLabel: l10n.instrumentsSwitchRace,
                isSwitcherOpen: _isSwitcherOpen,
                onToggleSwitcher: isSwitchable
                    ? () => setState(() => _isSwitcherOpen = !_isSwitcherOpen)
                    : null,
              ),
              onOpenMap: () => unawaited(
                Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const SafetyMapScreen()),
                ),
              ),
              onStop: session is EngineStopped
                  ? null
                  : () => unawaited(_confirmStop(context, l10n)),
            ),
            // Az infrastruktúra-hibasor a warningok FÖLÖTT áll (ADR 0042
            // D12).
            if (serviceError != null)
              WarningStrip(
                message: l10n.liveServiceError(serviceError),
                severity: WarningSeverity.critical,
                background: Theme.of(context).colorScheme.errorContainer,
                icon: Icons.error_outline,
              ),
            WarningBanner(warnings: warnings),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: gridOpacity,
                      child: _grid(context, l10n, snapshot, prediction),
                    ),
                  ),
                  if (_isSwitcherOpen && isSwitchable)
                    Positioned.fill(
                      child: TodayRacesMenu(
                        races: todayRaces,
                        selectedRaceId: race.id,
                        heading: l10n.instrumentsTodayRaces,
                        toLocal: ref.watch(localWallClockProvider),
                        onSelected: (chosen) => unawaited(_choose(chosen)),
                        onDismissed: () =>
                            setState(() => _isSwitcherOpen = false),
                      ),
                    ),
                ],
              ),
            ),
            // Az akció az Opacity-n KÍVÜL: kritikus warning mellett is
            // nyomható.
            _actionBar(context, l10n, prediction?.mark),
          ],
        ),
      ),
    );
  }

  Widget _grid(
    BuildContext context,
    AppLocalizations l10n,
    RaceSnapshot? snapshot,
    MarkPrediction? prediction,
  ) {
    final boat = snapshot?.boatState;
    final isSpeedOverGround =
        boat?.speedThroughWater == null && boat?.speedOverGround != null;
    final speed = isSpeedOverGround
        ? boat?.speedOverGround
        : boat?.speedThroughWater;
    final targetPercent = snapshot?.targetSpeedPercent;
    final steerSide = arrowSideFromSign(snapshot?.vmgSteerCorrection?.degrees);
    final vmgTarget = formatVmgTarget(snapshot?.targetVmgKnots);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _mainColumn(context, l10n, prediction)),
        DataRail(
          cells: [
            // Egy sebesség-cella: STW, ha nincs, SOG; a felirat vált
            // (`phone-ui-v1.md` §6). A BEARING helyén áll.
            RailCell(
              label: isSpeedOverGround ? l10n.liveSog : l10n.liveStw,
              value: formatSpeedLive(speed),
            ),
            RailCell(
              label: l10n.liveDistance,
              value: formatDistance(prediction?.distanceToMark),
            ),
            RailCell(
              label: l10n.liveEta,
              value: formatEta(
                prediction?.eta,
                minutesUnit: l10n.etaMinutesUnit,
              ),
            ),
            RailCell(
              label: l10n.liveTargetSpeed,
              value: formatTargetSpeedPercent(targetPercent),
            ),
            RailCell(
              label: l10n.liveVmg,
              value: formatVmgLive(snapshot?.vmgKnots),
              support: vmgTarget == null ? null : l10n.liveVmgTarget(vmgTarget),
              // A VMG-steer korrekció a cél-érték mellett (ADR 0042 D3).
              supportArrow: steerSide == ArrowSide.none
                  ? null
                  : SideArrow(
                      side: steerSide,
                      glyph: ArrowGlyph.line,
                      size: 11,
                    ),
              hasDivider: false,
            ),
          ],
        ),
      ],
    );
  }

  // A bal oldali műszer-oszlop; a flex-arányok az 1c-ből (1.6 / 1.15 / 1.0,
  // ADR 0042 D1), egész számként, mert a Flex csak azt fogad el.
  Widget _mainColumn(
    BuildContext context,
    AppLocalizations l10n,
    MarkPrediction? prediction,
  ) {
    final correction = prediction?.courseCorrection;
    final wind = ref.watch(windDataProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 160,
          child: PredictedTwaCell(
            twa: prediction?.predictedTwaAtMark,
            twdQuality: ref.watch(twdQualityProvider),
            confidence: prediction?.shiftConfidence,
            bandDegrees: prediction?.forecastBandDegrees,
          ),
        ),
        _hairline(context),
        Expanded(
          flex: 115,
          child: MainColumnCell(
            label: l10n.liveCorrection,
            support: _correctionHint(context, l10n, correction),
            child: CorrectionValue(correction, style: numeralLargeStyle),
          ),
        ),
        _hairline(context),
        Expanded(
          flex: 100,
          child: MainColumnCell(
            label: l10n.liveTwaNow,
            child: TwaValue(wind?.trueAngleWater, style: numeralMediumStyle),
          ),
        ),
      ],
    );
  }

  // A cellák közötti 1 dp-s elválasztó (ADR 0042 D1).
  Widget _hairline(BuildContext context) => SizedBox(
    height: 1,
    child: ColoredBox(color: Theme.of(context).colorScheme.outlineVariant),
  );

  // A korrekció kísérőszövege; 0°/null esetén nincs oldal, nincs felirat.
  Widget? _correctionHint(
    BuildContext context,
    AppLocalizations l10n,
    Angle? correction,
  ) {
    final side = arrowSideFromSign(correction?.degrees);
    if (side == ArrowSide.none) return null;
    // A foretackTheme regisztrálja a TextTones-t.
    final tones = Theme.of(context).extension<TextTones>()!;
    return Text(
      side == ArrowSide.right
          ? l10n.liveCorrectionRight
          : l10n.liveCorrectionLeft,
      style: supportTextStyle.copyWith(color: tones.low),
    );
  }

  // Az alsó, él-től él-ig érő akció (`phone-ui-v1.md` §6): rajt előtt a
  // „Rajt most" lejátszás-ikonnal, versenyen a „Bója megvan" ikon nélkül.
  Widget _actionBar(BuildContext context, AppLocalizations l10n, Mark? mark) {
    final isPreStart = widget.isPreStart;
    final label = Text(
      isPreStart ? l10n.instrumentsStartNow : l10n.liveRoundMark,
    );
    final style = FilledButton.styleFrom(
      textStyle: supportTextStyle.copyWith(
        fontSize: _actionLabelSize,
        fontWeight: FontWeight.w600,
      ),
      shape: const RoundedRectangleBorder(),
    );
    final onPressed = isPreStart
        ? () => unawaited(_confirmStart(context, l10n))
        : () => unawaited(_confirmRoundMark(context, l10n, mark));
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: actionBarHeight,
          child: isPreStart
              ? FilledButton.icon(
                  style: style,
                  onPressed: onPressed,
                  icon: const Icon(Icons.play_arrow),
                  label: label,
                )
              : FilledButton(style: style, onPressed: onPressed, child: label),
        ),
      ),
    );
  }

  // A váltó: a választott verseny ma a kézi választás (ADR 0055 D5), és a
  // nap versenye azonnal újra dönt. A lista zár; a tartalom a következő
  // pillanatképpel vált az új versenyre.
  Future<void> _choose(Race race) async {
    final chooser = ref.read(instrumentsRaceChooserProvider);
    setState(() => _isSwitcherOpen = false);
    if (race.id == widget.race.id) return;
    try {
      await chooser(race);
    } on Object catch (error) {
      // Egy tár-hiba nem dönthet le a vízen: a választás elmarad, az
      // engine a mostani versenyt vezeti tovább.
      developer.log('instruments choice failed: $error', name: 'Instruments');
    }
  }

  // A „Rajt most": megerősítés után a rajt előtti verseny lesz a
  // kiválasztott, és a részlet Rajtjával azonos úton indul (a lifecycle
  // küldi az engine-nek, ADR 0054 D5). A notifiert a dialógus előtt fogjuk
  // el: közben a tartalom válthat, és ez a `State` kieshet a fából.
  Future<void> _confirmStart(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final activeRace = ref.read(activeRaceProvider.notifier);
    final confirmed = await showForetackDialog<bool>(
      context: context,
      title: l10n.instrumentsStartTitle,
      message: l10n.instrumentsStartMessage,
      subject: (leading: null, name: widget.race.name, trailing: null),
      actions: [
        ForetackDialogAction(label: l10n.instrumentsStartCancel, value: false),
        ForetackDialogAction(label: l10n.instrumentsStartConfirm, value: true),
      ],
    );
    // A dialógus alatt az engine maga is rajtolhatott a tervezett időben
    // (ADR 0055 D6): ilyenkor a nézet már a versenyé (ugyanaz a kulcs), és
    // a kézi rajt felülírná a tervezett rajtidőt. A friss példány számít.
    if (confirmed != true || !mounted || !widget.isPreStart) return;
    final race = widget.race;
    if (race.status != RaceStatus.notStarted) return;
    activeRace.activeRace = race;
    try {
      await activeRace.start();
    } on Object catch (error) {
      // Egy mentési hiba nem dönthet le a vízen; a felhasználó újrapróbál.
      developer.log('manual start failed: $error', name: 'Instruments');
    }
  }

  // A „Bója megvan": megerősítés után roundMark parancs az engine-nek (az
  // auto-detektor kézi párja, ADR 0024). A célbója sorszámmal és névvel a
  // 35d adatcellájában, ha ismert.
  Future<void> _confirmRoundMark(
    BuildContext context,
    AppLocalizations l10n,
    Mark? mark,
  ) async {
    final host = ref.read(raceEngineHostProvider);
    final confirmed = await showForetackDialog<bool>(
      context: context,
      title: l10n.liveRoundMarkTitle,
      message: l10n.liveRoundMarkMessageGeneric,
      subject: mark == null
          ? null
          : (
              leading: mark.sequence.toString().padLeft(2, '0'),
              name: mark.name,
              trailing: null,
            ),
      actions: [
        ForetackDialogAction(label: l10n.liveRoundMarkCancel, value: false),
        ForetackDialogAction(label: l10n.liveRoundMarkConfirm, value: true),
      ],
    );
    if (confirmed != true) return;
    host.sendRoundMarkCommand();
  }

  // A „Leállítás" a ⋮ menüből: versenyen a „Verseny leállítása", rajt előtt
  // a szabad móddal azonos „Műszerek leállítása" (a verseny még nem
  // indult, csak az engine áll le). A notifiert a dialógus előtt fogjuk el.
  Future<void> _confirmStop(BuildContext context, AppLocalizations l10n) async {
    final session = ref.read(engineSessionProvider.notifier);
    final isPreStart = widget.isPreStart;
    final confirmed = await showForetackDialog<bool>(
      context: context,
      title: isPreStart ? l10n.instrumentsStopTitle : l10n.liveStopTitle,
      message: isPreStart ? l10n.instrumentsStopMessage : l10n.liveStopMessage,
      actions: [
        ForetackDialogAction(label: l10n.liveStopCancel, value: false),
        ForetackDialogAction(
          label: l10n.liveStopConfirm,
          value: true,
          isDestructive: true,
        ),
      ],
    );
    if (confirmed != true) return;
    session.stopManually();
  }
}
