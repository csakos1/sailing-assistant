import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/tick_provider.dart';
import 'package:phone/providers/wind_history_provider.dart';

/// A 7.4 `CalculateWindShiftTrend` use case provider-wrappere (ADR 0010 D2,
/// ARCHITECTURE.md 8.6).
///
/// A sliding-window regresszió CSAK a tick-en fut: a `windHistory`-t a
/// `ref.listen` tartja életben (autoDispose ellen), az értékét a tick
/// pillanatában olvassuk. A 10 perces ablak egyelőre in-memory konstans
/// (ADR 0010 D3); a runtime-konfig az 5f (SettingsRepository). `null`, amíg
/// nincs első tick, vagy ha a use case nem ad trendet (< 10 minta / degenerált).
final windShiftTrendProvider = AutoDisposeProvider<WindShiftTrend?>((ref) {
  final tick = ref.watch(tickProvider).valueOrNull;
  ref.listen(windHistoryProvider, (_, _) {});
  if (tick == null) {
    return null;
  }
  return const CalculateWindShiftTrend()(
    history: ref.read(windHistoryProvider),
    window: const Duration(minutes: 10),
    now: tick,
  );
});
