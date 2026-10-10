import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/engine_service_error_provider.dart';
import 'package:phone/providers/engine_session_provider.dart';
import 'package:phone/providers/engine_session_state.dart';
import 'package:phone/providers/engine_session_timings_provider.dart';
import 'package:phone/providers/last_recording_reader_provider.dart';
import 'package:phone/providers/polar_provider.dart';
import 'package:phone/providers/race_engine_host_provider.dart';
import 'package:phone/providers/race_engine_lifecycle.dart';
import 'package:phone/providers/timer_factory_provider.dart';
import 'package:shared/shared.dart';

/// A háttér-engine életciklusa (ADR 0054 D5): a [RaceEngineLifecycle]-t a
/// session-állapothoz és a kiválasztott versenyhez köti. Az app-gyökér
/// eager-watch-olja; az „Élő nézet" a `handOver`-t, az
/// `AppForegroundBinding` az `onAppResumed` / `onAppPaused`-t hívja rajta.
final raceEngineLifecycleProvider = Provider<RaceEngineLifecycle>((ref) {
  final lifecycle = RaceEngineLifecycle(
    host: ref.watch(raceEngineHostProvider),
    session: ref.read(engineSessionProvider.notifier),
    readActiveRace: () => ref.read(activeRaceProvider),
    loadPolar: () => _loadPolar(ref),
    reportServiceError: (error) =>
        ref.read(engineServiceErrorProvider.notifier).state = error,
    persistEngineFinish: (raceId, at) =>
        ref.read(activeRaceProvider.notifier).finishFromEngine(raceId, at: at),
    readLastRecordingAt: ref.watch(lastRecordingReaderProvider),
    adoptTimeout: ref.watch(engineSessionTimingsProvider).adoptTimeout,
    now: ref.watch(clockProvider),
    createTimer: ref.watch(timerFactoryProvider),
  );
  ref
    ..onDispose(lifecycle.dispose)
    ..listen<EngineSessionState>(
      engineSessionProvider,
      lifecycle.onSessionChanged,
      // Egy újraépülés a session aktuális állapotából induljon. Futó
      // sessionnél ez az engine újraindítását jelenti; ma a függőségek
      // állandók, így újraépülés nem fordul elő.
      fireImmediately: true,
    )
    ..listen<Race?>(activeRaceProvider, lifecycle.onActiveRaceChanged);
  return lifecycle;
});

/// A polár betöltése a `polarProvider`-ből; hiba/hiányzó polár → `null`
/// (a háttér-engine null-polárral fut, a cél-sebesség `null`).
Future<Polar?> _loadPolar(Ref ref) async {
  final result = await ref.read(polarProvider.future);
  return switch (result) {
    Ok(:final value) => value,
    Err() => null,
  };
}
