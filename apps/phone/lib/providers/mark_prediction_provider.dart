import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/boat_state_provider.dart';
import 'package:phone/providers/tick_provider.dart';
import 'package:phone/providers/wind_shift_trend_provider.dart';

/// A 7.8 `ComputeMarkPrediction` composite provider-wrappere — a v1 szíve
/// (ADR 0010 D2, ARCHITECTURE.md 8.6).
///
/// 1 Hz-en a tick-en újraszámol — akkor is, ha a trend tartósan null, miközben
/// a hajó mozog (ezért watch-olja a tick-et közvetlenül). A `boatState`/
/// `windShiftTrend` tick-időben olvasott snapshot (a `ref.listen` keep-alive);
/// az `activeRace` keep-alive → sima `ref.read`. Az aktív bóyát a
/// `Race.activeMarkOrNull` adja; null race / finished → activeMark null → a
/// use case `null`-t ad.
final markPredictionProvider = AutoDisposeProvider<MarkPrediction?>((ref) {
  final tick = ref.watch(tickProvider).valueOrNull;
  ref
    ..listen(boatStateProvider, (_, _) {})
    ..listen(windShiftTrendProvider, (_, _) {});
  if (tick == null) {
    return null;
  }
  final race = ref.read(activeRaceProvider);
  return const ComputeMarkPrediction()(
    activeMark: race?.activeMarkOrNull,
    boatState: ref.read(boatStateProvider),
    trend: ref.read(windShiftTrendProvider),
    now: tick,
  );
});
