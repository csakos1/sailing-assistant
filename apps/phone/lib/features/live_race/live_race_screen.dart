import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/screen_wake_lock.dart';
import 'package:phone/features/live_race/live_formatters.dart';
import 'package:phone/features/live_race/widgets/confidence_dots.dart';
import 'package:phone/features/live_race/widgets/correction_value.dart';
import 'package:phone/features/live_race/widgets/live_status_bar.dart';
import 'package:phone/features/live_race/widgets/metric_cell.dart';
import 'package:phone/features/live_race/widgets/metric_value_text.dart';
import 'package:phone/features/live_race/widgets/twa_value.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/boat_state_provider.dart';
import 'package:phone/providers/connection_status_provider.dart';
import 'package:phone/providers/mark_prediction_provider.dart';
import 'package:phone/providers/screen_wake_lock_provider.dart';
import 'package:phone/providers/tick_provider.dart';
import 'package:phone/providers/wind_data_provider.dart';

/// Az élő verseny-képernyő (§8.7): a compute-rétegből fogyaszt, és a 7 v1
/// értéket jeleníti meg fix 2×3 rácsban + státuszsorban, ~1 Hz-en.
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
    // Verseny közben fix portrait: a 2×3 rács landscape-ben rosszul reflow-ol.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final race = ref.watch(activeRaceProvider);
    final prediction = ref.watch(markPredictionProvider);
    final wind = ref.watch(windDataProvider);
    final boat = ref.watch(boatStateProvider);
    final status = ref.watch(connectionStatusProvider);
    final tick = ref.watch(tickProvider).valueOrNull;

    if (race == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.liveNoActiveRace)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(race.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              LiveStatusBar(
                connectionStatus: status,
                markName: race.activeMarkOrNull?.name,
                instrumentTimeUtc: boat.instrumentTimeUtc,
                isStale: _isStale(status: status, boat: boat, tick: tick),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    MetricCell(
                      label: l10n.liveTwaNow,
                      child: TwaValue(wind?.trueAngleWater),
                    ),
                    MetricCell(
                      label: l10n.liveTwaNext,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TwaValue(prediction?.predictedTwaAtMark),
                          if (prediction != null) ...[
                            const SizedBox(height: 4),
                            ConfidenceDots(prediction.shiftConfidence),
                          ],
                        ],
                      ),
                    ),
                    MetricCell(
                      label: l10n.liveBearing,
                      child: MetricValueText(
                        formatBearing(prediction?.bearingToMark),
                      ),
                    ),
                    MetricCell(
                      label: l10n.liveCorrection,
                      child: CorrectionValue(prediction?.courseCorrection),
                    ),
                    MetricCell(
                      label: l10n.liveDistance,
                      child: MetricValueText(
                        formatDistance(prediction?.distanceToMark),
                      ),
                    ),
                    MetricCell(
                      label: l10n.liveEta,
                      child: MetricValueText(
                        formatEta(
                          prediction?.eta,
                          minutesUnit: l10n.etaMinutesUnit,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
