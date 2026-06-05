import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/rotary/rotary_page_stepper.dart';

/// A natív rotary EventChannel neve (a watch `MainActivity` ezen küldi a perem
/// `AXIS_SCROLL`-deltáit). Stringként egyeznie kell a Kotlin oldallal.
const String rotaryScrollChannelName = 'com.csakos.foretack/rotary';

/// A perem nyers scroll-deltáinak forrása (DIP-seam a tesztelhetőségért).
typedef RotaryScrollSource = Stream<double> Function();

/// A nyers perem-delta forrás. Éles esetben a natív EventChannel broadcast
/// streamje; tesztben fake `Stream<double>`-lel override-olható.
final rotaryScrollSourceProvider = Provider<RotaryScrollSource>((ref) {
  return () => const EventChannel(
    rotaryScrollChannelName,
  ).receiveBroadcastStream().map((event) => (event as num).toDouble());
});

/// A nyers perem-deltákból derivált, nem-nulla lap-lépések streamje. A
/// küszöbölést egy lokális [RotaryPageStepper] végzi (akkumulátor-állapot a
/// stream élettartamára); a view ezt figyeli és lépteti a `PageController`-t.
Stream<int> rotaryPageSteps(Stream<double> deltas) {
  final stepper = RotaryPageStepper();
  return deltas.map(stepper.addDelta).where((steps) => steps != 0);
}

/// A perem-forgatásból derivált lap-lépések streamje (ADR 0015 Addendum). A
/// view `ref.listen`-eli, és a kapott előjeles lépéssel lapoz. Keep-alive: a
/// nav a primary kijelző teljes életében él (ADR 0016).
final rotaryPageStepProvider = StreamProvider<int>((ref) {
  final source = ref.watch(rotaryScrollSourceProvider);
  return rotaryPageSteps(source());
});
