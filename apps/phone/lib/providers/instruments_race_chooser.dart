import 'package:domain/domain.dart';

/// A Műszerek váltójának írása (ADR 0055 D5, ADR 0056 U4): a választott
/// versenyt a mai napra kézi választásként menti, és utána szól, hogy a
/// nap versenye azonnal újra döntsön.
///
/// A sorrend számít: az értesítés csak a mentés után fut, mert a
/// lifecycle a választást a tárból olvassa újra.
class InstrumentsRaceChooser {
  /// A választó a tár írójával, az órával, a helyi naptárral és a mentés
  /// utáni értesítéssel.
  InstrumentsRaceChooser({
    required Future<void> Function(InstrumentsRaceChoice choice) write,
    required DateTime Function() now,
    required LocalWallClock toLocal,
    required void Function() onChosen,
  }) : _write = write,
       _now = now,
       _toLocal = toLocal,
       _onChosen = onChosen;

  final Future<void> Function(InstrumentsRaceChoice choice) _write;
  final DateTime Function() _now;
  final LocalWallClock _toLocal;
  final void Function() _onChosen;

  /// A [race] legyen ma a Műszerek versenye.
  Future<void> call(Race race) async {
    await _write(
      InstrumentsRaceChoice(
        raceId: race.id,
        chosenOnLocalDay: _toLocal(_now()),
      ),
    );
    _onChosen();
  }
}
