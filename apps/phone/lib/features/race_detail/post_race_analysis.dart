import 'package:domain/domain.dart';
import 'package:phone/features/race_detail/track_point.dart';

/// A befejezett verseny on-device post-race elemzésének projekciója
/// (ADR 0034). A megkerülésenkénti eredmények és a belőlük számolt összegző
/// együtt; a `RaceDetailScreen` debug-szekciója ([RoundingResult]-kártyák +
/// [RoundingSummary]-fej) ezt jeleníti meg. Az Addendum 3 óta a track
/// nyers pontjait és a track-statokat is hordozza (release-ben látható), az
/// Addendum 4 óta a pontok a sebességet ([TrackPoint.sogMps]) is viszik a
/// gradient-színezéshez.
class PostRaceAnalysis {
  /// Az elemzés eredménye és összegzője, plusz a track adatai. A track-mezők
  /// alapértelmezett üres/üres-stat értéke a régebbi hívókat (és teszteket)
  /// változatlanul hagyja.
  const PostRaceAnalysis({
    required this.roundings,
    required this.summary,
    this.trackPoints = const [],
    this.trackStats = const TrackStats(),
  });

  /// A megkerülésenkénti eredmények időrendben (üres, ha nincs adat).
  final List<RoundingResult> roundings;

  /// A megkerülésekből számolt összegző mutatók.
  final RoundingSummary summary;

  /// A vitorlázott track pontjai időrendben, sebességgel annotálva (a
  /// térkép-polyline csúcsai; üres, ha nincs rögzített pozíció).
  final List<TrackPoint> trackPoints;

  /// A track sebesség- és úthossz-statisztikái (ADR 0034 Addendum 3).
  final TrackStats trackStats;

  /// Nincs elemezhető megkerülés — a next-TWA blokk üres-állapotának jele
  /// (ADR 0034 D5).
  bool get isEmpty => roundings.isEmpty;
}
