import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// A szél-mondat referenciakerete (MWV R/T flag).
///
/// `apparent` = a hajóhoz képest mért látszólagos szél (MWV `R`);
/// `true_` = a Vulcan által számolt valódi szél (MWV `T`).
enum WindReference { apparent, true_ }

/// Egy tipizált, dekódolt NMEA 0183 mondat.
///
/// A `SentenceDecoder` (ARCHITECTURE.md 6.3) állítja elő a nyers
/// `Sentence`-ből; a mapper (6.4) alakítja `DomainEvent`(ek)re. Sealed,
/// hogy a mapper exhaustive `switch`-csel minden ágat kötelezően kezeljen.
@immutable
sealed class DecodedSentence {
  /// Csak a leaf subclass-ok hívják.
  const DecodedSentence();
}

/// Apparent vagy true szél (MWV); a [reference] dönti el, melyik.
final class DecodedWind extends DecodedSentence {
  /// Dekódolt szél-mondatot csomagol.
  const DecodedWind({
    required this.reference,
    required this.angle,
    required this.speed,
  });

  /// Apparent (MWV `R`) vagy true (MWV `T`) referencia.
  final WindReference reference;

  /// Szél-szög a hajó orrához képest, signed `[-180, +180)`.
  final Angle angle;

  /// Szélsebesség m/s-ban (a wire-egységet a dekóder váltja át).
  final Speed speed;
}

/// A valódi szélirány (MWD) — ground-referenciás TWD + szélsebesség.
final class DecodedWindDirection extends DecodedSentence {
  /// Dekódolt szélirány-mondatot csomagol.
  const DecodedWindDirection({required this.direction, required this.speed});

  /// A valódi szélirány (TWD), trueNorth-referenciás `[0, 360)`.
  final Bearing direction;

  /// Szélsebesség m/s-ban.
  final Speed speed;
}
