import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

/// Az éjszakai mód újraértékelésének üteme (ADR 0039 D9).
///
/// Hiszterézis nincs: a napállás monoton, a küszöböt naponta kétszer, egy
/// irányba lépi át — nincs mit lecsillapítani.
const Duration nightModeReevaluationPeriod = Duration(minutes: 1);

/// Az éjszaka szimmetrikus szűkítése (ADR 0039 D7).
///
/// A mód a napnyugta után ennyivel kapcsol be, és a napkelte előtt ennyivel
/// ki. v1-ben nulla; a geometriai napnyugtakor még világos van, tehát az első
/// vízi tapasztalat után ezt az egy számot érdemes hangolni.
const Duration nightModeOffset = Duration.zero;

/// Fejlesztői kényszerítés: `--dart-define=FORETACK_FORCE_NIGHT=true`.
///
/// Nem felhasználói felület (ADR 0039 D10) — enélkül az on-device
/// verifikáció napnyugtára várást jelentene. A `bool.fromEnvironment` csak a
/// literál `true`-t fogadja el.
const bool forceNightMode = bool.fromEnvironment('FORETACK_FORCE_NIGHT');

/// A pillanatnyi UTC-idő forrása (seam a tesztelhetőségért).
typedef UtcClock = DateTime Function();

/// A fali-óra seam. Élesben a rendszeróra, tesztben felülírható.
///
/// Szándékosan NEM a `WatchClock`: az GPS-anchor híján `untrusted`, tehát az
/// első payload előtt nem tudna témát választani — márpedig az app indulásakor
/// már a helyes témával kell megjelenni (ADR 0039 D8).
final utcClockProvider = Provider<UtcClock>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

/// Igaz, ha éjszaka van a Balaton fölött; percenként újraértékelve.
///
/// Az óra maga számol, a `WatchPayload` nem bővül (ADR 0039 D6), így a mód
/// kapcsolat-vesztéskor és az első payload előtt is helyes.
final nightModeProvider = NotifierProvider<NightModeNotifier, bool>(
  NightModeNotifier.new,
);

/// A [nightModeProvider] notifiere: a napállásból számolja a mód állapotát.
class NightModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final timer = Timer.periodic(
      nightModeReevaluationPeriod,
      (_) => _reevaluate(),
    );
    ref.onDispose(timer.cancel);
    return _evaluate();
  }

  void _reevaluate() {
    final next = _evaluate();
    // Csak valódi váltásnál írunk állapotot: enélkül percenként újraépülne a
    // teljes widget-fa a témával együtt.
    if (next != state) {
      state = next;
    }
  }

  bool _evaluate() {
    if (forceNightMode) {
      return true;
    }
    return isNightAt(
      nowUtc: ref.read(utcClockProvider)(),
      latitudeDegrees: balatonReferenceLatitude,
      longitudeDegrees: balatonReferenceLongitude,
      offset: nightModeOffset,
    );
  }
}
