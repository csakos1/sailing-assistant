import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

/// A riasztó rezgés hossza (ARCHITECTURE.md 11.3).
const Duration depthBuzzDuration = Duration(milliseconds: 1500);

/// A sekély-víz riasztás rezgését absztraháló varrat (DIP, ADR 0031 D4,
/// ARCHITECTURE.md 11.3).
///
/// **Függvény-varrat, nem interface.** Egyetlen műveletről van szó, és az
/// `apps/watch` több seamje is így van megoldva (`rotaryScrollSourceProvider`,
/// `roundMarkSenderProvider`). A `RaceOngoingActivity` azért osztály, mert
/// két művelete van (start/stop) — egytagúnál az egytagú abstract class csak
/// ceremónia, amit a `one_member_abstracts` lint helyesen kifogásol.
///
/// A `RaceShell` ezen át rezeg a `depthBuzzCounter` változó élén; a tesztek
/// egy számláló kém tear-offjával helyettesítik (nincs natív hívás).
typedef DepthAlertVibrator = Future<void> Function();

// A `vibration` csomag amplitúdó-skálája 1..255; a -1 a platform
// alapértelmezését kéri (amplitúdó-vezérlés nélküli eszközön ez az egyetlen
// érvényes érték).
const int _maxAmplitude = 255;
const int _platformDefaultAmplitude = -1;

/// A `vibration` csomagot használó konkrét rezgés — az `apps/watch` egyetlen
/// rezgés-érintő pontja, a [depthAlertVibratorProvider] alapértelmezése.
///
/// A `HapticFeedback.heavyImpact()` (amit a konfidencia-buzz használ) nem tud
/// sem hosszt, sem amplitúdót, ezért a zátony-riasztáshoz nem elég: az vízen,
/// kesztyűben, hullámzásban elveszik.
Future<void> buzzDepthAlert() async {
  // Graceful degradáció, a WearOngoingActivityAdapter mintájára: a rezgés a
  // vizuális overlay mellett "nice-to-have", ezért egy natív hiba NE bukjon
  // ki a widget-fába, csak látható logba kerüljön a hajós diagnosztikához.
  try {
    final hasAmplitude = await Vibration.hasAmplitudeControl();
    await Vibration.vibrate(
      duration: depthBuzzDuration.inMilliseconds,
      amplitude: hasAmplitude ? _maxAmplitude : _platformDefaultAmplitude,
    );
  } on Object catch (error) {
    debugPrint('Foretack: depth alert vibration failed: $error');
  }
}

/// Az `apps/watch` rezgés-varrata. Default a `vibration` csomagot használó
/// [buzzDepthAlert]; a tesztek kémmel felülírják.
final depthAlertVibratorProvider = Provider<DepthAlertVibrator>(
  (ref) => buzzDepthAlert,
);
