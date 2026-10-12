import 'package:domain/src/entities/race.dart';
import 'package:domain/src/entities/race_status.dart';
import 'package:meta/meta.dart';

/// Pure use case: folytathatja-e az app magától egy `active` versenyt, amikor
/// a gateway-próba megtalálja a hajót (ADR 0054 E3).
///
/// A verseny akkor folytatódik, ha a legutóbbi tevékenysége (a legutóbbi
/// rögzített pillanatkép, vagy ha az nincs, a rajt) [maximumGap]-nél
/// frissebb. A naptári nap szándékosan nem számít: egy kétnapos verseny
/// (pl. a Kékszalag) éjfél után is folytatódik, mert a felvétele folyamatos,
/// egy elfelejtett „Cél" utáni másnapi vitorlázás viszont nem kerül a régi
/// verseny felvételébe, mert a rés órákban mérhető.
///
/// A jövőbeli tevékenység (eltérő órák) friss tevékenységnek számít.
@immutable
class IsRaceResumable {
  /// Állapotmentes use case; a [maximumGap] alapértéke 6 óra.
  const IsRaceResumable({this.maximumGap = defaultMaximumGap});

  /// Az alapértelmezett leghosszabb rés a legutóbbi tevékenység óta.
  static const Duration defaultMaximumGap = Duration(hours: 6);

  /// Ennél régebbi tevékenység után a verseny nem folytatódik magától.
  final Duration maximumGap;

  /// `true`, ha a [race] `active`, és a legutóbbi tevékenysége a [now]-hoz
  /// képest [maximumGap]-nél frissebb. A [lastRecordedAt] a legutóbbi
  /// rögzített pillanatkép ideje (`null`: nincs felvétel).
  bool call({
    required Race race,
    required DateTime? lastRecordedAt,
    required DateTime now,
  }) {
    if (race.status != RaceStatus.active) return false;
    final startedAt = race.startedAt;
    final lastActivity = _latest(startedAt, lastRecordedAt);
    if (lastActivity == null) return false;
    return now.difference(lastActivity) < maximumGap;
  }

  static DateTime? _latest(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
}
