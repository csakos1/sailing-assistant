import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/boat_state_provider.dart';
import 'package:phone/providers/connection_status_provider.dart';
import 'package:phone/providers/polar_provider.dart';
import 'package:phone/providers/race_snapshot_provider.dart';
import 'package:phone/providers/tick_provider.dart';
import 'package:phone/providers/true_time_provider.dart';
import 'package:phone/providers/wind_shift_trend_provider.dart';
import 'package:shared/shared.dart';

/// A Fázis 6 `EvaluateWarnings` use case provider-wrappere (ADR 0014,
/// ARCHITECTURE.md 11.2): az aktív warningok 1 Hz-en frissülő listája.
///
/// A `markPredictionProvider` (8.6) mintáját követi. A tick-en újraszámol —
/// a warning-szabályok nem `now`-függők (ADR 0014 D2), de a tick adja a
/// screennel közös 1 Hz kadenciát és az első emit előtti `const []` kaput.
/// Az autoDispose inputokat (`connectionStatusProvider`, `boatStateProvider`,
/// `windShiftTrendProvider`, `raceSnapshotProvider`) a `ref.listen` tartja
/// életben; a keep-alive `activeRaceProvider` és `trueTimeProvider` sima
/// `ref.read`. A
/// `polarProvider` (keep-alive `Future`) `ref.watch`-csal: az `Err`-ága
/// (hiányzó/hibás polár-asset) adja az `isPolarMissing` kaput; amíg tölt
/// (`valueOrNull == null`), NEM jelez. A `depthAlertMeters` az engine-
/// snapshotból jön (ADR 0031 D4): a sekély-víz epizód-állapotgép a
/// háttér-izolátumban fut, ez a provider csak tükrözi.
///
/// A domain nem ismeri az apps/phone true-time típusait (ADR 0012 DD2), ezért
/// az `isTimeUnsynced` / `timeStreamDrift` primitíveket itt, a provider-
/// határon képezzük a `TrueTimeReading`-ből.
final activeWarningsProvider = AutoDisposeProvider<List<Warning>>((ref) {
  final tick = ref.watch(tickProvider).valueOrNull;
  final polarResult = ref.watch(polarProvider).valueOrNull;
  ref
    ..listen(connectionStatusProvider, (_, _) {})
    ..listen(boatStateProvider, (_, _) {})
    ..listen(windShiftTrendProvider, (_, _) {})
    ..listen(raceSnapshotProvider, (_, _) {});
  if (tick == null) {
    return const <Warning>[];
  }

  final boatState = ref.read(boatStateProvider);
  final trueTime = ref.read(trueTimeProvider)();
  final race = ref.read(activeRaceProvider);

  // A drift előjele trueTime − instrument; v1-ben irreleváns (a use case
  // abszolútértékkel, szigorú >-vel dönt, ADR 0014 D7), de a konvenció
  // rögzített. null, ha bármelyik oldal hiányzik.
  final utc = trueTime.utc;
  final instrumentUtc = boatState.instrumentTimeUtc;
  final timeStreamDrift = (utc != null && instrumentUtc != null)
      ? utc.difference(instrumentUtc)
      : null;

  return const EvaluateWarnings()(
    connectionStatus: ref.read(connectionStatusProvider),
    boatState: boatState,
    windShiftTrend: ref.read(windShiftTrendProvider),
    raceStatus: race?.status ?? RaceStatus.notStarted,
    isTimeUnsynced: trueTime.source == TrueTimeSource.wallClockUnsynced,
    timeStreamDrift: timeStreamDrift,
    isPolarMissing: polarResult is Err<Polar, PolarLoadError>,
    depthAlertMeters: ref.read(raceSnapshotProvider)?.depthAlertMeters,
  );
});
