import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/engine/gateway_probe_loop.dart';
import 'package:phone/providers/engine_session_provider.dart';
import 'package:phone/providers/engine_session_state.dart';
import 'package:phone/providers/engine_session_timings_provider.dart';
import 'package:phone/providers/gateway_probe_provider.dart';
import 'package:phone/providers/timer_factory_provider.dart';

/// A gateway-próba futtatása, amíg a session [EngineProbing] (ADR 0054 D4).
/// Mellékhatás-provider: az app-gyökér eager-watch-olja. Találatkor a
/// session `gatewayFound()`-ot kap, és az engine elindul.
final gatewayProbeLoopProvider = Provider<void>((ref) {
  final loop = GatewayProbeLoop(
    probe: ref.watch(gatewayProbeProvider),
    interval: ref.watch(engineSessionTimingsProvider).probeInterval,
    onFound: () => ref.read(engineSessionProvider.notifier).gatewayFound(),
    createTimer: ref.watch(timerFactoryProvider),
  );
  ref
    ..onDispose(loop.stop)
    ..listen<EngineSessionState>(engineSessionProvider, (_, next) {
      if (next is EngineProbing) {
        loop.start();
      } else {
        loop.stop();
      }
    }, fireImmediately: true);
});
