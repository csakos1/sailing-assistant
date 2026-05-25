import 'package:domain/src/entities/mark.dart';
import 'package:domain/src/use_cases/calculate_distance_to_mark.dart';
import 'package:domain/src/value_objects/coordinate.dart';
import 'package:domain/src/value_objects/distance.dart';

/// Bóya-megkerülés (rounding) detektálása a hajó távolság-profiljából.
///
/// **Domain háttér.** Egy bóyát akkor tekintünk megkerültnek, ha a hajó
/// előbb a közelébe ért (egy küszöbtávolságon belülre), majd elkezdett
/// tőle érdemben távolodni. A detektor a "legközelebbi pont után
/// távolodás" mintát figyeli: tickenként összeveti az aktuális
/// távolságot az eddig látott minimummal. Ez vezérli a verseny
/// előrehaladását — az aktív bóyáról a következőre váltást.
///
/// **Stateful — szándékosan NEM pure.** A többi 7.x use case-szel
/// szemben ez állapotot tart: az eddig elért legkisebb távolságot
/// ([_minDistanceSoFar]). Enélkül nem megkülönböztethető a "közeledünk"
/// és a "már túlhaladtunk, távolodunk" fázis. Ezért nincs `const` ctor
/// és nincs `@immutable`; egy aktív bóyához egy detektor-példány
/// tartozik, ami túléli a tickeket.
///
/// **Level-trigger szerződés.** A [tick] **minden** ticken `true`-t ad,
/// amíg a feltétel fennáll (a hajó egy korábban a küszöbön belül
/// megközelített bóyától a hiszterézist meghaladva távolodik) — nem
/// egyszeri él-esemény. A hívó (application réteg) felelőssége, hogy az
/// első `true`-ra kezelje az eseményt (a következő bóyára vált) és
/// [reset]-et hívjon. Szinkron consumer esetén ez a gyakorlatban
/// egyetlen `true`.
///
/// **Küszöb + hiszterézis.** A [_thresholdMeters] (50 m) rögzíti,
/// mennyire kellett megközelíteni a bóyát ahhoz, hogy a megkerülést
/// egyáltalán számoljuk — egy 100 m-re elhúzó hajó nem kerüli meg. A
/// [_hysteresisMeters] (5 m) a GPS-jitter elnyomása: csak akkor számít
/// távolodásnak, ha a minimumhoz képest ennél többet nőtt a távolság,
/// különben a pozíció-zaj a legközelebbi pont körül folyamatosan
/// triggerelne.
class MarkRoundingDetector {
  /// Megkerülési küszöb (m): a hajónak valaha ennyin belülre kellett
  /// kerülnie ahhoz, hogy a távolodás megkerülésnek számítson.
  static const double _thresholdMeters = 50;

  /// Hiszterézis (m): a minimumhoz képest ennél nagyobb távolodás
  /// számít valódi elhúzásnak — a GPS-jitter elnyomására.
  static const double _hysteresisMeters = 5;

  /// Példányszintű, determinisztikus távolságszámító. A Haversine pure,
  /// ezért nem injektáljuk; egyetlen const példányt használunk.
  final CalculateDistanceToMark _distanceToMark =
      const CalculateDistanceToMark();

  /// Az eddig elért legkisebb távolság a bóyától, vagy `null` ha még
  /// nem érkezett tick (vagy [reset] után). A "közeledünk vs.
  /// távolodunk" döntés alapja.
  Distance? _minDistanceSoFar;

  /// Egy tick: a [boatPosition] és a [targetMark] alapján frissíti a
  /// belső minimumot, és visszaadja, hogy a bóya megkerültnek
  /// tekinthető-e. Level-trigger; a [reset]-szerződés a class-doc-ban.
  bool tick(Coordinate boatPosition, Mark targetMark) {
    final distance = _distanceToMark(boatPosition, targetMark.position);
    final minSoFar = _minDistanceSoFar;

    // Első tick, vagy még közeledünk → frissítjük a minimumot, nincs
    // megkerülés. A null-check lokálissal, nem `!` force-unwrappal.
    if (minSoFar == null || distance.meters < minSoFar.meters) {
      _minDistanceSoFar = distance;
      return false;
    }

    // Most távolodunk. Megkerülés, ha valaha a küszöbön belül voltunk
    // ÉS a hiszterézist meghaladva nőtt a távolság.
    return minSoFar.meters <= _thresholdMeters &&
        distance.meters > minSoFar.meters + _hysteresisMeters;
  }

  /// A belső állapot nullázása — új aktív bóyára váltáskor hívandó,
  /// hogy a következő bóya megkerülése tisztán detektálható legyen.
  void reset() {
    _minDistanceSoFar = null;
  }
}
