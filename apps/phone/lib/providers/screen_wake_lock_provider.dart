import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/screen_wake_lock.dart';
import 'package:phone/app/wakelock_plus_screen_wake_lock.dart';

/// A képernyő-wakelock vezérlőjét adó keep-alive provider.
///
/// Keep-alive, mert a `LiveRaceScreen` a `dispose`-ban is az itt kapott
/// instance-on hív `disable()`-t; nem akarjuk, hogy közben eldobódjon.
final screenWakeLockProvider = Provider<ScreenWakeLock>(
  (ref) => const WakelockPlusScreenWakeLock(),
);
