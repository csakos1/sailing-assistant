import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/engine_session_state.dart';

/// A háttér-engine sessionjének állapotgépe (ADR 0054 D4, D5; az ADR 0017
/// A12 bool flagjének utódja).
///
/// Tiszta állapotgép: a hosthoz nem nyúl. A mellékhatásokat (indítás,
/// leállítás, parancsok) a `raceEngineLifecycleProvider` végzi az állapot
/// változására, a próbát a `gatewayProbeLoopProvider`. Induláskor
/// [EngineStopped]: a boot-restore nem indít engine-t (A12), az app a
/// próbával kezd, amint előtérben van.
final engineSessionProvider =
    NotifierProvider<EngineSessionNotifier, EngineSessionState>(
      EngineSessionNotifier.new,
    );

/// Az [engineSessionProvider] notifierje. Minden átmenet idempotens: egy
/// nem odaillő állapotban hívott metódus nem csinál semmit.
class EngineSessionNotifier extends Notifier<EngineSessionState> {
  // A 10 perces leállás után ettől függ, hogy újra próbálunk-e.
  bool _isForeground = false;

  @override
  EngineSessionState build() => const EngineStopped();

  /// Az app előtérbe került: leállított állapotból indul a próba. Csak
  /// háttérből visszatérve; egy már előtérben lévő app ismételt jelzése
  /// (pl. az `inactive` után) nem írja felül a kézi leállítást.
  void appResumed() {
    final wasForeground = _isForeground;
    _isForeground = true;
    if (!wasForeground && state is EngineStopped) {
      state = const EngineProbing();
    }
  }

  /// Az app háttérbe került: a próba szünetel, a futó engine nem áll le.
  void appPaused() {
    _isForeground = false;
    if (state is EngineProbing) state = const EngineStopped();
  }

  /// A próba megtalálta a hajót.
  void gatewayFound() {
    if (state is EngineProbing) {
      state = const EngineRunning(cause: EngineStartCause.gatewayFound);
    }
  }

  /// Kézi indítás („Élő nézet", „Rajt"); egy futó engine-t nem indít újra.
  void startManually() {
    if (state is! EngineRunning) {
      state = const EngineRunning(cause: EngineStartCause.user);
    }
  }

  /// Egy már futó háttér-engine átvétele (az app-folyamat újraindult, a
  /// service nem).
  void adoptRunningEngine() {
    if (state is! EngineRunning) {
      state = const EngineRunning(cause: EngineStartCause.adopted);
    }
  }

  /// Kézi „Leállítás": a próba csak a következő előtérbe kerüléskor indul,
  /// különben a leállítás a hajó mellett azonnal visszafordulna.
  void stopManually() => state = const EngineStopped();

  /// Az engine leállt magától (szabad módban 10 percig nem volt kapcsolat),
  /// vagy már nem fut: előtérben újra próbál, háttérben leáll.
  void stopAfterIdle() {
    if (state is! EngineRunning) return;
    state = _isForeground ? const EngineProbing() : const EngineStopped();
  }

  /// A foreground service nem indult el (pl. hiányzó engedély). Nem próbál
  /// újra azonnal, hogy ne ismételje 5 mp-enként ugyanazt a hibát; a
  /// következő előtérbe kerüléskor igen.
  void startFailed() {
    if (state is EngineRunning) state = const EngineStopped();
  }
}
