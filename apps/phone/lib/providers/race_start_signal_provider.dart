import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Egy rajt jelzése: a verseny azonosítója és egy növekvő sorszám.
///
/// A sorszám miatt két rajt akkor is két külön érték, ha a rekordok
/// egyébként egyenlők lennének (a rekord értékegyenlőséget ad).
typedef RaceStartSignal = ({String raceId, int serial});

/// A kiválasztott verseny rajtjának explicit jelzése (ADR 0056 D2).
///
/// Az `ActiveRaceNotifier` jelez, ha a kiválasztott verseny elindul: kézi
/// „Rajt", vagy az engine rajtjának átvétele; és az
/// `activeRacePersistenceProvider`, ha induláskor egy folytatható futó versenyt
/// tölt vissza (ADR 0056 U3). A héj erre vált a Műszerek fülre. Esemény, nem
/// állapot-következtetés: a kiválasztott verseny változásából (egy rég futó
/// verseny kiválasztása, egy késve átvett, órákkal korábbi tervezett rajt) nem
/// dönthető el megbízhatóan, hogy rajt történt-e. Keep-alive, mint az aktív
/// verseny.
final raceStartSignalProvider =
    NotifierProvider<RaceStartSignalNotifier, RaceStartSignal?>(
      RaceStartSignalNotifier.new,
    );

/// A [raceStartSignalProvider] notifierje.
class RaceStartSignalNotifier extends Notifier<RaceStartSignal?> {
  @override
  RaceStartSignal? build() => null;

  /// A [raceId] verseny rajtjának jelzése.
  void signal(String raceId) {
    state = (raceId: raceId, serial: (state?.serial ?? 0) + 1);
  }
}
