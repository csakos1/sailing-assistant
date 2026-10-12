import 'dart:developer' as developer;

import 'package:domain/domain.dart';

/// A „nap versenye" kiválasztásának eredménye: a kiválasztott verseny
/// (`null`: szabad mód) és a lista, amiből született. A listából az
/// életciklus egy már átadott verseny friss példányát is kikeresi (ADR 0055
/// D8: a rajt előtti szerkesztés új `race` parancs).
typedef InstrumentsRaceSelection = ({Race? dayRace, List<Race> races});

/// A `SelectInstrumentsRace` (ADR 0055 D5) bemeneteinek összegyűjtése és
/// meghívása.
///
/// A versenyek a DB-ből jönnek; a UI-ban kiválasztott verseny csak akkor
/// kerül a listába, ha a DB-ben nincs meg, mert a DB példánya legalább
/// olyan friss (a notifier minden átmenetet ment, a szerkesztés pedig csak a
/// DB-t írja). Az aktív verseny felvételének ideje és a kézi választás
/// olvasási hibája nem állítja meg a kiválasztást: hiányzó adatként
/// számít.
class InstrumentsRaceSelector {
  /// Kiválasztó a megadott forrásokkal. Élesben a `now` a telefon
  /// rendszerórája (ADR 0055 „Pontosítás (T4)"), a `toLocal` a
  /// `DateTime.toLocal`.
  InstrumentsRaceSelector({
    required Future<List<Race>> Function() readRaces,
    required Race? Function() readSelectedRace,
    required LastRecordingReader readLastRecordingAt,
    required Future<InstrumentsRaceChoice?> Function() readChoice,
    required DateTime Function() now,
    required LocalWallClock toLocal,
    SelectInstrumentsRace select = const SelectInstrumentsRace(),
  }) : _readRaces = readRaces,
       _readSelectedRace = readSelectedRace,
       _readLastRecordingAt = readLastRecordingAt,
       _readChoice = readChoice,
       _now = now,
       _toLocal = toLocal,
       _select = select;

  final Future<List<Race>> Function() _readRaces;
  final Race? Function() _readSelectedRace;
  final LastRecordingReader _readLastRecordingAt;
  final Future<InstrumentsRaceChoice?> Function() _readChoice;
  final DateTime Function() _now;
  final LocalWallClock _toLocal;
  final SelectInstrumentsRace _select;

  /// A mostani kiválasztás. A versenyek olvasási hibája a hívóhoz megy
  /// (az életciklus naplózza, és szabad módban marad).
  Future<InstrumentsRaceSelection> call() async {
    final races = _withSelectedRace(await _readRaces());
    final active = SelectInstrumentsRace.latestActiveRace(races);
    final lastRecordedAt = active == null
        ? null
        : await _orNull(() => _readLastRecordingAt(active.id));
    final choice = await _orNull(_readChoice);
    final dayRace = _select(
      races: races,
      now: _now().toUtc(),
      toLocal: _toLocal,
      activeRaceLastRecordedAt: lastRecordedAt,
      manualChoice: choice,
    );
    return (dayRace: dayRace, races: races);
  }

  List<Race> _withSelectedRace(List<Race> races) {
    final selected = _readSelectedRace();
    if (selected == null || races.any((race) => race.id == selected.id)) {
      return races;
    }
    return [...races, selected];
  }

  static Future<T?> _orNull<T>(Future<T?> Function() read) async {
    try {
      return await read();
    } on Object catch (error) {
      // Hiányzó adatként kezeljük: a kiválasztás nélküle is dönt.
      developer.log(
        'selection input read failed: $error',
        name: 'InstrumentsRaceSelector',
      );
      return null;
    }
  }
}
