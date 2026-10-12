import 'dart:async';

import 'package:phone/engine/gateway_probe.dart';
import 'package:phone/engine/timer_factory.dart';

/// A gateway-próba ismétlése, amíg a hajó elő nem kerül (ADR 0054 D4).
///
/// Az első próba a [start]-kor azonnal fut, a következő az előző
/// eredménye után `interval` múlva — így egy lassú (timeoutig tartó) próba
/// nem fut párhuzamosan a következővel. Találatkor a ciklus megáll, és
/// egyszer hívja az `onFound`-ot. A [stop] után egy még futó próba
/// eredménye elveszik.
class GatewayProbeLoop {
  /// Ciklus a [probe]-bal, [interval] szünettel a próbák között.
  GatewayProbeLoop({
    required GatewayProbe probe,
    required Duration interval,
    required void Function() onFound,
    TimerFactory createTimer = Timer.new,
  }) : _probe = probe,
       _interval = interval,
       _onFound = onFound,
       _createTimer = createTimer;

  final GatewayProbe _probe;
  final Duration _interval;
  final void Function() _onFound;
  final TimerFactory _createTimer;

  Timer? _timer;
  // Minden start/stop új generációt nyit; egy régi próba eredményét eldobjuk.
  int _generation = 0;
  bool _isRunning = false;

  /// Fut-e a ciklus.
  bool get isRunning => _isRunning;

  /// Elindítja a ciklust; ha már fut, nem csinál semmit.
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    final generation = ++_generation;
    unawaited(_probeOnce(generation));
  }

  /// Leállítja a ciklust; a függő időzítőt törli.
  void stop() {
    _isRunning = false;
    _generation++;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _probeOnce(int generation) async {
    _timer = null;
    final bool isFound;
    try {
      isFound = await _probe();
    } on Object {
      // Védekezés: egy dobó próba (akár `Error`) se akassza meg a ciklust;
      // különben az `_isRunning` igaz maradna, és a `start` no-op lenne.
      _scheduleNext(generation);
      return;
    }
    if (generation != _generation) return;
    if (isFound) {
      stop();
      _onFound();
      return;
    }
    _scheduleNext(generation);
  }

  void _scheduleNext(int generation) {
    if (generation != _generation) return;
    _timer = _createTimer(_interval, () => unawaited(_probeOnce(generation)));
  }
}
