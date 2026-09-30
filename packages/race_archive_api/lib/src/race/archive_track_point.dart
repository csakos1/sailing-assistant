import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

/// Egy track-pont a webes részletezőhöz: pozíció és a pillanatnyi SOG.
///
/// A phone `TrackPoint`-jának dróton utazó párja (ADR 0047 Addendum 1
/// A4). Külön típus, mert a phone-é az app rétegében él. A web a közös
/// widgetek bemenetére képezi le.
final class ArchiveTrackPoint extends Equatable {
  /// Track-pont a [position]-on, opcionális [sogMps] sebességgel.
  const ArchiveTrackPoint({required this.position, this.sogMps});

  /// A pont pozíciója.
  final Coordinate position;

  /// Speed over ground m/s-ban; `null`, ha a mintában nem volt SOG.
  final double? sogMps;

  @override
  List<Object?> get props => [position, sogMps];
}
