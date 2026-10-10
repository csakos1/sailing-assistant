import 'dart:async';

/// Test timer factory: records every timer and fires them by hand, so the
/// probe loop and the idle watch are tested without real waiting.
class FakeTimers {
  /// Every timer created so far, in order.
  final List<FakeTimer> created = [];

  /// The timers not yet fired or cancelled.
  List<FakeTimer> get active => [
    for (final timer in created)
      if (timer.isActive) timer,
  ];

  /// Matches `TimerFactory`; pass it as `fakeTimers.create`.
  Timer create(Duration duration, void Function() callback) {
    final timer = FakeTimer(duration, callback);
    created.add(timer);
    return timer;
  }
}

/// A timer that fires only when the test calls [fire].
class FakeTimer implements Timer {
  FakeTimer(this.duration, this._callback);

  /// The requested delay.
  final Duration duration;
  final void Function() _callback;
  bool _isActive = true;

  @override
  bool get isActive => _isActive;

  @override
  int get tick => 0;

  @override
  void cancel() => _isActive = false;

  /// Runs the callback once, unless cancelled.
  void fire() {
    if (!_isActive) return;
    _isActive = false;
    _callback();
  }
}
