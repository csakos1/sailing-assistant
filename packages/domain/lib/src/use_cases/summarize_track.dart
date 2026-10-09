import 'package:domain/src/use_cases/calculate_distance_to_mark.dart';
import 'package:domain/src/value_objects/coordinate.dart';
import 'package:domain/src/value_objects/track_sample.dart';
import 'package:domain/src/value_objects/track_stats.dart';
import 'package:meta/meta.dart';

/// A track-statisztikák kiszámítása a rögzített pillanatképek
/// `TrackSample`-mintáiból (ADR 0034 Addendum 3).
///
/// Két statisztika-család:
///
/// - **Sebesség**: a `TrackSample.sogMps` nem-null mintáiból a maximum
///   és a számtani átlag. Ha egyetlen mintának sincs sebessége, mindkettő
///   `null`.
/// - **Úthossz**: a szomszédos érvényes pozíciók (`latDeg`/`lonDeg`
///   mindkettő non-null) közti haversine-szakaszok nyers összege, a
///   kanonikus [CalculateDistanceToMark] kompozíciójával (DRY — nem
///   duplikáljuk a földsugarat és a képletet). Kettőnél kevesebb érvényes
///   pozíció esetén `null`.
///
/// **Pure use case**: nincs állapot, idempotens. Az úthossz nyers,
/// jitter-szűrés nélküli (v2). A hiányzó pozíciójú minták nem szakítják
/// meg az úthossz-láncot: kihagyjuk őket, és a következő érvényes
/// pozíciót az előzőhöz láncoljuk.
///
/// A bemenet szándékosan a keskeny `TrackSample` szerződés, nem a teljes
/// `RoundingSample` read-modell (ISP, ADR 0044 Addendum 4): a számításnak
/// három mennyiség kell, így egy olcsóbb, projekciós olvasó is
/// kiszolgálhatja anélkül, hogy a teljes pillanatképet visszaépítené.
@immutable
class SummarizeTrack {
  /// Const ctor — a use case stateless, példány-egyenlőség nem releváns;
  /// const-elve egyetlen instance is elég.
  const SummarizeTrack();

  /// A [samples] listából aggregált [TrackStats]. Részletek a class-doc-ban.
  TrackStats call(List<TrackSample> samples) {
    double? maxSpeedMps;
    var speedSum = 0.0;
    var speedCount = 0;

    // A sebesség-statok a nem-null sogMps mintákból, egyetlen bejárásban.
    for (final sample in samples) {
      final sog = sample.sogMps;
      if (sog == null) continue;
      speedSum += sog;
      speedCount++;
      if (maxSpeedMps == null || sog > maxSpeedMps) {
        maxSpeedMps = sog;
      }
    }

    return TrackStats(
      maxSpeedMps: maxSpeedMps,
      avgSpeedMps: speedCount > 0 ? speedSum / speedCount : null,
      distanceMeters: _totalDistanceMeters(samples),
    );
  }

  /// A szomszédos érvényes pozíciók közti haversine-szakaszok összege,
  /// vagy `null`, ha kettőnél kevesebb érvényes pozíció van.
  double? _totalDistanceMeters(List<TrackSample> samples) {
    const calculateDistance = CalculateDistanceToMark();
    Coordinate? previous;
    double? total;

    for (final sample in samples) {
      final position = _positionOf(sample);
      if (position == null) continue;
      if (previous != null) {
        total = (total ?? 0) + calculateDistance(previous, position).meters;
      }
      previous = position;
    }
    return total;
  }

  /// A minta pozíciója [Coordinate]-ként, vagy `null`, ha bármelyik
  /// koordináta hiányzik. A lat/lon a data-olvasóban a már validált
  /// `boatState.position`-ból jött, így a default ctor elég.
  Coordinate? _positionOf(TrackSample sample) {
    final lat = sample.latDeg;
    final lon = sample.lonDeg;
    if (lat == null || lon == null) return null;
    return Coordinate(latitude: lat, longitude: lon);
  }
}
