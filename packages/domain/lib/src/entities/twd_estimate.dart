import 'package:domain/src/entities/twd_quality.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Egy derivált True Wind Direction (TWD) becslés a minőségével együtt
/// (ADR 0020).
///
/// A `DeriveTrueWindDirection` use case adja vissza. **Invariáns:** a
/// [twd] akkor és csak akkor `null`, ha a [quality]
/// [TwdQuality.unavailable] — `live`/`held` esetén mindig van [twd]. Az
/// invariánst Dart 3 exhaustive switch őrzi: új [TwdQuality] érték
/// hozzáadásakor a fordító itt jelez először.
@immutable
class TwdEstimate extends Equatable {
  /// Derivált becslés. Az invariánst (lásd class-doc) assert védi —
  /// property-access assert miatt a ctor non-const.
  TwdEstimate({required this.twd, required this.quality})
    : assert(
        _invariantHolds(twd, quality),
        'twd akkor és csak akkor null, ha quality == unavailable.',
      );

  /// Nincs becslés: [twd] `null`, [quality] [TwdQuality.unavailable].
  const TwdEstimate.unavailable()
    : twd = null,
      quality = TwdQuality.unavailable;

  /// A derivált TWD (trueNorth), vagy `null` ha [quality] unavailable.
  final Bearing? twd;

  /// A becslés minősége (live / held / unavailable).
  final TwdQuality quality;

  static bool _invariantHolds(Bearing? twd, TwdQuality quality) =>
      switch (quality) {
        TwdQuality.live || TwdQuality.held => twd != null,
        TwdQuality.unavailable => twd == null,
      };

  @override
  List<Object?> get props => [twd, quality];

  @override
  bool? get stringify => true;
}
