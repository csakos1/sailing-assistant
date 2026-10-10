import 'dart:async';

import 'package:domain/domain.dart';
import 'package:phone/engine/timer_factory.dart';

/// Szabad módban ennyi kapcsolat nélküli idő után áll le az engine
/// (ADR 0054 D5).
const Duration freeModeIdleTimeout = Duration(minutes: 10);

/// A szabad módú engine automatikus leállítása kapcsolat nélkül
/// (ADR 0054 D5). A háttér-engine izolátumában fut (a task handlerben),
/// mert kikapcsolt kijelzőnél a UI-izolátum időzítői állnak (ADR 0016).
///
/// Csak akkor számol, ha az engine szabad módban van (nincs verseny, vagy a
/// verseny már befejezett) **és** nincs kapcsolat a gatewayjel. Ha ez
/// `timeout`-ig fennáll, egyszer hívja az `onIdle`-t. Rajt előtt és
/// versenyen soha: egy rövid WiFi-kiesés a vízen nem állíthatja le az
/// engine-t. Egy kapcsolódás vagy egy verseny a számlálót nullázza.
class FreeModeIdleWatch {
  /// Figyelő a [timeout] türelmi idővel.
  FreeModeIdleWatch({
    required Duration timeout,
    required void Function() onIdle,
    TimerFactory createTimer = Timer.new,
  }) : _timeout = timeout,
       _onIdle = onIdle,
       _createTimer = createTimer;

  final Duration _timeout;
  final void Function() _onIdle;
  final TimerFactory _createTimer;

  Timer? _timer;
  bool _isWatching = false;
  bool _isFreeMode = false;
  bool _isConnected = false;

  /// Az engine indulásakor: [isFreeMode] a kezdő mód. Az első pillanatképig
  /// nincs kapcsolatnak számít, így egy pillanatképet sem adó engine is
  /// leáll szabad módban.
  void begin({required bool isFreeMode}) {
    _isWatching = true;
    _isFreeMode = isFreeMode;
    _isConnected = false;
    _update();
  }

  /// Egy pillanatkép állapota: a [raceStatus] (`null` = szabad mód) és a
  /// [connectionStatus].
  void observe({
    required RaceStatus? raceStatus,
    required ConnectionStatus connectionStatus,
  }) {
    if (!_isWatching) return;
    _isFreeMode = raceStatus == null || raceStatus == RaceStatus.finished;
    _isConnected = connectionStatus is Connected;
    _update();
  }

  /// Az engine leállásakor: a figyelés véget ér, a számláló törlődik.
  void end() {
    _isWatching = false;
    _cancel();
  }

  void _update() {
    if (_isWatching && _isFreeMode && !_isConnected) {
      _timer ??= _createTimer(_timeout, _fire);
    } else {
      _cancel();
    }
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void _fire() {
    _timer = null;
    _isWatching = false;
    _onIdle();
  }
}
