import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/screen_wake_lock.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/features/live_race/live_formatters.dart';
import 'package:phone/features/live_race/target_speed.dart';
import 'package:phone/features/live_race/widgets/correction_value.dart';
import 'package:phone/features/live_race/widgets/data_rail.dart';
import 'package:phone/features/live_race/widgets/live_status_bar.dart';
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
import 'package:phone/providers/boat_state_provider.dart';
import 'package:phone/providers/connection_status_provider.dart';
import 'package:phone/providers/engine_service_error_provider.dart';
import 'package:phone/providers/gps_time_reading_provider.dart';
import 'package:phone/providers/mark_prediction_provider.dart';
import 'package:phone/providers/race_engine_host_provider.dart';
import 'package:phone/providers/race_engine_session_provider.dart';
import 'package:phone/providers/race_snapshot_provider.dart';
import 'package:phone/providers/screen_wake_lock_provider.dart';
import 'package:phone/providers/tick_provider.dart';
import 'package:phone/providers/twd_quality_provider.dart';
import 'package:phone/providers/wind_data_provider.dart';

/// Az élő verseny-képernyő (§8.7): a compute-rétegből fogyaszt, és a nyolc
/// v1 értéket jeleníti meg az 1c műszer-oszlop elrendezésben (ADR 0042),
/// ~1 Hz-en.
///
/// A providereket a gyökéren `watch`-olja, ami transitive életben tartja a
/// teljes §8.6 láncot, és felépíti a lusta connectiont (ADR 0010 D5). Az
/// `AppLocalizations.of` `!`-ja biztonságos a `MaterialApp` alatt.
///
/// `ConsumerStatefulWidget`, mert a kijelző-wakelockot és a portrait-lockot a
/// mount/unmount életciklushoz kötjük: `initState`-ben be, `dispose`-ban ki.
class LiveRaceScreen extends ConsumerStatefulWidget {
  /// Az élő verseny-képernyő.
  const LiveRaceScreen({super.key});

  @override
  ConsumerState<LiveRaceScreen> createState() => _LiveRaceScreenState();
}

class _LiveRaceScreenState extends ConsumerState<LiveRaceScreen> {
  // A dispose-ban már nem olvasunk providert (a ref ott nem biztonságos),
  // ezért a wakelock-instance-t az initState-ben fogjuk el.
  late final ScreenWakeLock _wakeLock;

  @override
  void initState() {
    super.initState();
    _wakeLock = ref.read(screenWakeLockProvider);
    unawaited(_wakeLock.enable());
    // Verseny közben fix portrait: a műszer-oszlop és a sín landscape-ben
    // rosszul reflow-ol.
    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );
  }

  @override
  void dispose() {
    unawaited(_wakeLock.disable());
    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
    super.dispose();
  }

  // A „Leállítás" akció: megerősítés után billenti a session-flaget
  // false-ra (a lifecycle ettől állítja le a háttér-engine-t), majd
  // visszanavigál.
  Future<void> _confirmStop(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.liveStopTitle),
        content: Text(l10n.liveStopMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.liveStopCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.liveStopConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(raceEngineSessionProvider.notifier).stop();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  // A „Bója megvan" akció: megerősítés után roundMark parancsot küld az
  // engine-nek, ami lépteti az aktív bóját (a `_maybeRoundMark` kézi párja).
  // Pontatlan boja-koordinátánál ez a gyors megoldás, amikor az auto-
  // detektor 50 m-es küszöbét sosem éri el. A célbója nevét csak akkor
  // mutatjuk, ha ismert (nincs GPS-pozíciónál a generikus szöveg megy).
  Future<void> _confirmRoundMark(
    BuildContext context,
    AppLocalizations l10n,
    String? markName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.liveRoundMarkTitle),
        content: Text(
          markName == null
              ? l10n.liveRoundMarkMessageGeneric
              : l10n.liveRoundMarkMessage(markName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.liveRoundMarkCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.liveRoundMarkConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(raceEngineHostProvider).sendRoundMarkCommand();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final race = ref.watch(activeRaceProvider);
    final prediction = ref.watch(markPredictionProvider);
    final twdQuality = ref.watch(twdQualityProvider);
    final wind = ref.watch(windDataProvider);
    final boat = ref.watch(boatStateProvider);
    final snapshot = ref.watch(raceSnapshotProvider);
    // A cél-sebesség %: a snapshot live sebessége és a polár célja
    // alapján (ugyanaz a tick). Cél híján gondolatjel, nem 0%.
    final boatSnapshot = snapshot?.boatState;
    final targetPercent = targetSpeedPercent(
      liveSpeedMetersPerSecond:
          (boatSnapshot?.speedThroughWater ?? boatSnapshot?.speedOverGround)
              ?.metersPerSecond,
      targetSpeedKnots: snapshot?.targetSpeedKnots,
    );
    final status = ref.watch(connectionStatusProvider);
    final tick = ref.watch(tickProvider).valueOrNull;
    final gpsTime =
        ref.watch(gpsTimeReadingProvider).valueOrNull ??
        const TrueTimeReading(utc: null, source: TrueTimeSource.none);
    final warnings = ref.watch(activeWarningsProvider);
    final serviceError = ref.watch(engineServiceErrorProvider);
    final hasCriticalWarning = warnings.any(
      (warning) => warning.severity == WarningSeverity.critical,
    );
    // Critical warningnál a rács 40%-ra tompul (nem rejtve) — a fókusz a
    // banneren maradjon (ADR 0014 D6).
    final gridOpacity = hasCriticalWarning ? 0.4 : 1.0;

    if (race == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.liveNoActiveRace)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(race.name, style: screenTitleStyle),
        actions: [
          // A biztonsági térkép a versenyhez tartozik, ezért innen nyílik
          // (ADR 0037 D16). A leállítás marad a szélén: azt keresi a kéz
          // vakon is, és nem szabad, hogy egy új gomb elcsúsztassa.
          IconButton(
            onPressed: () => unawaited(
              Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const SafetyMapScreen()),
              ),
            ),
            icon: const Icon(Icons.map_outlined),
            tooltip: l10n.safetyMapOpen,
          ),
          IconButton(
            onPressed: () => unawaited(_confirmStop(context, l10n)),
            icon: const Icon(Icons.stop_circle_outlined),
            tooltip: l10n.liveStop,
          ),
        ],
      ),
      // Az 1c elrendezés él-től élig ér: az elválasztást hairline-ok végzik,
      // nem margó és nem cella-rés (ADR 0042 D1).
      body: SafeArea(
        child: Column(
          children: [
            LiveStatusBar(
              connectionStatus: status,
              markName: prediction?.mark.name ?? race.activeMarkOrNull?.name,
              trueTime: gpsTime,
              isStale: _isStale(status: status, boat: boat, tick: tick),
            ),
            // Az infrastruktúra-hibasor a warningok FÖLÖTT áll: az
            // engine-indítás hibája megelőzi a verseny-warningokat, mert
            // nélküle nincs is miből warningot számolni (ADR 0042 D12).
            if (serviceError != null)
              WarningStrip(
                message: l10n.liveServiceError(serviceError),
                severity: WarningSeverity.critical,
                background: Theme.of(context).colorScheme.errorContainer,
                icon: Icons.error_outline,
              ),
            WarningBanner(warnings: warnings),
            Expanded(
              child: Opacity(
                opacity: gridOpacity,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _mainColumn(
                        context,
                        l10n,
                        prediction: prediction,
                        twdQuality: twdQuality,
                        wind: wind,
                      ),
                    ),
                    DataRail(
                      cells: _railCells(
                        l10n,
                        prediction: prediction,
                        targetPercent: targetPercent,
                        vmgKnots: snapshot?.vmgKnots,
                        targetVmgKnots: snapshot?.targetVmgKnots,
                        vmgSteerCorrection: snapshot?.vmgSteerCorrection,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Manuális bója-megkerülés: csak active alatt, és az Opacity-n
            // KÍVÜL, hogy kritikus warning mellett (tompított rács) is
            // léptethess.
            if (race.status == RaceStatus.active)
              _roundMarkButton(context, l10n, prediction?.mark.name),
          ],
        ),
      ),
    );
  }

  // A bal oldali műszer-oszlop. A flex-arányok az 1c makettből valók
  // (1.6 / 1.15 / 1.0, ADR 0042 D1); egész számként írjuk, mert a Flex csak
  // azt fogad el.
  Widget _mainColumn(
    BuildContext context,
    AppLocalizations l10n, {
    required MarkPrediction? prediction,
    required TwdQuality twdQuality,
    required WindData? wind,
  }) {
    final correction = prediction?.courseCorrection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 160,
          child: PredictedTwaCell(
            twa: prediction?.predictedTwaAtMark,
            twdQuality: twdQuality,
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

  // A jobb oldali adatsín öt cellája; az utolsó alatt nincs hairline, mert
  // ott a sín véget ér.
  List<Widget> _railCells(
    AppLocalizations l10n, {
    required MarkPrediction? prediction,
    required double? targetPercent,
    required double? vmgKnots,
    required double? targetVmgKnots,
    required Angle? vmgSteerCorrection,
  }) {
    final steerSide = arrowSideFromSign(vmgSteerCorrection?.degrees);
    final vmgTarget = formatVmgTarget(targetVmgKnots);
    return [
      RailCell(
        label: l10n.liveBearing,
        value: formatBearing(prediction?.bearingToMark),
      ),
      RailCell(
        label: l10n.liveDistance,
        value: formatDistance(prediction?.distanceToMark),
      ),
      RailCell(
        label: l10n.liveEta,
        value: formatEta(prediction?.eta, minutesUnit: l10n.etaMinutesUnit),
      ),
      RailCell(
        label: l10n.liveTargetSpeed,
        value: formatTargetSpeedPercent(targetPercent),
      ),
      RailCell(
        label: l10n.liveVmg,
        value: formatVmgLive(vmgKnots),
        support: vmgTarget == null ? null : l10n.liveVmgTarget(vmgTarget),
        // A VMG-steer korrekció itt, a cél-érték mellett kap helyet — az 1c
        // elrendezésben nincs saját cellája (ADR 0042 D3).
        supportArrow: steerSide == ArrowSide.none
            ? null
            : SideArrow(side: steerSide, glyph: ArrowGlyph.line, size: 11),
        hasDivider: false,
      ),
    ];
  }

  // A cellák közötti 1 dp-s elválasztó; a rácsnak nincs se rése, se
  // radiusa (ADR 0042 D1).
  Widget _hairline(BuildContext context) => SizedBox(
    height: 1,
    child: ColoredBox(color: Theme.of(context).colorScheme.outlineVariant),
  );

  // A korrekció kísérőszövege; 0°/null esetén nincs oldal, tehát nincs
  // felirat sem.
  Widget? _correctionHint(
    BuildContext context,
    AppLocalizations l10n,
    Angle? correction,
  ) {
    final side = arrowSideFromSign(correction?.degrees);
    if (side == ArrowSide.none) {
      return null;
    }
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    return Text(
      side == ArrowSide.right
          ? l10n.liveCorrectionRight
          : l10n.liveCorrectionLeft,
      style: supportTextStyle.copyWith(color: tones.low),
    );
  }

  // Az alsó akció-sáv magassága; a lajstrom sávjával egyezik
  // (ADR 0044 D14), hogy a két képernyő alja azonos alakú legyen.
  static const double _actionBarHeight = 60;

  // A felirat mérete a sáv magasságából származik, hogy a geometria
  // változásakor az arány magától kövesse (ADR 0042 Addendum 2).
  static const double _actionLabelSize = _actionBarHeight * 0.3;

  Widget _roundMarkButton(
    BuildContext context,
    AppLocalizations l10n,
    String? markName,
  ) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        height: _actionBarHeight,
        child: FilledButton(
          // Ikon nélkül és nagyobb felirattal: ez az egyetlen akció a
          // képernyőn, és kesztyűs kézzel, hullámzásban is el kell találni.
          // A gomb kitölti a sávot: éltől élig ér, radius nélkül
          // (ADR 0042 Addendum 2).
          style: FilledButton.styleFrom(
            textStyle: supportTextStyle.copyWith(
              fontSize: _actionLabelSize,
              fontWeight: FontWeight.w600,
            ),
            shape: const RoundedRectangleBorder(),
          ),
          onPressed: () =>
              unawaited(_confirmRoundMark(context, l10n, markName)),
          child: Text(l10n.liveRoundMark),
        ),
      ),
    ),
  );

  bool _isStale({
    required ConnectionStatus status,
    required BoatState boat,
    required DateTime? tick,
  }) {
    if (status is! Connected || tick == null) {
      return false;
    }
    return tick.difference(boat.lastUpdate) > const Duration(seconds: 5);
  }
}
