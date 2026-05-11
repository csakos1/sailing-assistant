import 'package:meta/meta.dart';
import 'package:shared/shared.dart';

/// Egy abszolút irány a kompasz-rózsán, fokban.
///
/// Immutable value object. A [degrees] tipikusan [0, 360) tartományban
/// értelmes (0 = észak, 90 = kelet, 180 = dél, 270 = nyugat), és a
/// [reference] jelzi mihez képest van mérve (geográfiai vagy mágneses
/// észak).
///
/// Háromféle létrehozási mód, eltérő bizalmi szintekre:
///
/// - [Bearing.new] (default const): nincs runtime validáció és nincs
///   normalize. Csak akkor használd, ha a hívó garantálja az
///   érvényességet (const literál, vagy belső, már normalize-zott adat).
/// - [Bearing.checked]: programozói hibára szabott. NaN vagy ±infinity
///   esetén [ArgumentError]-t dob; egyéb értékeket modulo 360-tal
///   normalize-zal [0, 360) tartományba.
/// - [Bearing.tryFromDegrees]: untrusted bemenethez. NaN vagy ±infinity
///   esetén [Err]; egyéb értékeket modulo 360-tal normalize-zal.
///
/// A referenciás design (true vs magnetic) szándékosan a típusban
/// hordozza a metaadatot, hogy egy magnetic és egy true Bearing
/// véletlenszerű összekeverése típusszinten elkapható legyen
/// (pl. a declination-konverzió hiánya hibákat okozna a számításokban).
@immutable
class Bearing {
  /// Default const konstruktor — nincs validáció, nincs normalize. Csak
  /// garantáltan normalize-zott input esetén használd (pl. const literál).
  const Bearing({required this.degrees, required this.reference});

  /// Programozói hiba védőhálója: NaN vagy ±infinity esetén
  /// [ArgumentError]-t dob. Egyéb értékeket modulo 360-tal normalize-zal.
  factory Bearing.checked({
    required double degrees,
    required BearingReference reference,
  }) {
    final result = Bearing.tryFromDegrees(
      degrees: degrees,
      reference: reference,
    );
    return switch (result) {
      Ok(value: final bearing) => bearing,
      Err(error: final err) => throw ArgumentError(err.toString()),
    };
  }

  /// Untrusted bemenet biztonságos validációja. NaN vagy ±infinity esetén
  /// [Err]; egyéb értékeket modulo 360-tal normalize-zal [0, 360) tartományba.
  static Result<Bearing, BearingError> tryFromDegrees({
    required double degrees,
    required BearingReference reference,
  }) {
    if (!degrees.isFinite) {
      return Err(BearingNotFinite(value: degrees));
    }
    // A Dart `double % double` mindig pozitív eredményt ad véges osztón,
    // így -10 % 360 = 350, 365 % 360 = 5, 360 % 360 = 0, -720 % 360 = 0.
    final normalized = degrees % 360;
    return Ok(Bearing(degrees: normalized, reference: reference));
  }

  /// Az irány fokban. Konstruktortól függően nem feltétlenül normalize-zott
  /// (lásd [Bearing.new]).
  final double degrees;

  /// Mihez képest van mérve — geográfiai (true north) vagy mágneses észak.
  final BearingReference reference;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bearing &&
          other.degrees == degrees &&
          other.reference == reference;

  @override
  int get hashCode => Object.hash(degrees, reference);

  @override
  String toString() => 'Bearing(deg: $degrees, ref: ${reference.name})';
}

/// Egy [Bearing] mihez van mérve.
enum BearingReference {
  /// Geográfiai (true) észak — a térkép szerinti északot mutatja, a Föld
  /// forgástengelye által definiált.
  trueNorth,

  /// Mágneses észak — egy iránytű mutatójának iránya. A geográfiai
  /// északtól pozícióonként és időpontonként eltér a mágneses elhajlás
  /// (declination) mértékében; ezt a WMM-modellel számoljuk.
  magneticNorth,
}

/// A [Bearing.tryFromDegrees] hibakód-típusa. Sealed, hogy a hívó
/// pattern matching-gel minden esetet kötelezően kezeljen.
@immutable
sealed class BearingError {
  /// Csak a [BearingNotFinite] subclass hívja.
  const BearingError();
}

/// A megadott érték NaN vagy ±infinity — nem véges számábrázolás.
@immutable
final class BearingNotFinite extends BearingError {
  /// Hibainfó: a bemeneti [value] (NaN vagy ±∞).
  const BearingNotFinite({required this.value});

  /// A bemeneti érték (NaN vagy ±infinity).
  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BearingNotFinite && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'BearingNotFinite(value: $value)';
}
