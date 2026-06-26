import 'package:domain/domain.dart';

/// Egy track-pont a post-race térképhez: a `Coordinate` pozíció a hozzá
/// tartozó pillanatnyi sebességgel (SOG, m/s). A sebesség a szakaszonkénti
/// gradient-színezéshez kell (ADR 0034 Addendum 4); `null`, ha az adott
/// mintából hiányzott a SOG.
///
/// Tisztán presentation-DTO: a domain a `Coordinate`-ot és a `sogMps`-t
/// külön hordozza (a `RoundingSample`-ben), itt a térkép-réteg fogja össze.
class TrackPoint {
  /// A [position] pozícióhoz a [sogMps] (m/s) sebességet rendeli.
  const TrackPoint({required this.position, this.sogMps});

  /// A track-pont földrajzi pozíciója.
  final Coordinate position;

  /// A pillanatnyi sebesség (SOG) m/s-ban; `null`, ha hiányzott.
  final double? sogMps;
}
