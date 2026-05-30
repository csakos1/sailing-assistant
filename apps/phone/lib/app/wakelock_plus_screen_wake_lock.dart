import 'package:phone/app/screen_wake_lock.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// A `wakelock_plus` pluginra épülő valós [ScreenWakeLock].
///
/// Ez az egyetlen hely, ahol a plugint közvetlenül hívjuk — így a screen a
/// [ScreenWakeLock] absztrakción át tesztelhető marad.
class WakelockPlusScreenWakeLock implements ScreenWakeLock {
  /// Plugin-alapú wakelock-vezérlőt hoz létre.
  const WakelockPlusScreenWakeLock();

  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();
}
