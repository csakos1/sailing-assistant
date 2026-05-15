import 'package:meta/meta.dart';
import 'package:shared/shared.dart';

/// Egy távolság, méterben mérve.
///
/// Immutable value object. A [meters] mező mindig **non-negatív** (>= 0)
/// és véges. A 0 = ugyanaz a pont (két azonos koordináta közötti
/// távolság). SI alapegységben (méter) tárol; az NM, km vagy mérföldes
/// formázás a presentation rétegben történik.
///
/// **Tudatosan unsigned.** A vitorlás szakzsargonban egy "negatív
/// távolság" valójában egy másik fogalom (cross-track error, start-line
/// offset, pálya-tengely menti pozíció) — ezek külön value object-ek
/// lesznek, ha kellenek. A Distance fogalma szigorúan a Haversine-szerű,
/// nem-irányított elválasztó hosszúság. Így egy
/// `Distance.checked(meters: -5)` argumentum hangos hiba, nem
/// hallgatólagos `abs()` korrekció.
///
/// Háromféle létrehozási mód, eltérő bizalmi szintekre:
///
/// - [Distance.new] (default const): nincs runtime validáció. Csak
///   akkor használd, ha a hívó garantálja az érvényességet (const
///   literál, vagy belső számítás eredménye, pl. Haversine).
/// - [Distance.checked]: programozói hibára szabott. NaN, ±infinity
///   vagy negatív érték esetén [ArgumentError]-t dob.
/// - [Distance.tryFromMeters]: untrusted bemenethez. NaN/±infinity
///   esetén [DistanceNotFinite]; negatív esetén [DistanceNegative].
@immutable
class Distance {
  /// Default const konstruktor — nincs validáció. Csak garantáltan
  /// érvényes input esetén használd (pl. const literál vagy belső
  /// számítás eredménye).
  const Distance({required this.meters});

  /// Programozói hiba védőhálója: NaN, ±infinity vagy negatív érték
  /// esetén [ArgumentError]-t dob.
  factory Distance.checked({required double meters}) {
    final result = Distance.tryFromMeters(meters: meters);
    return switch (result) {
      Ok(value: final distance) => distance,
      Err(error: final err) => throw ArgumentError(err.toString()),
    };
  }

  /// Untrusted bemenet biztonságos validációja. NaN vagy ±infinity esetén
  /// [DistanceNotFinite]; negatív érték esetén [DistanceNegative].
  static Result<Distance, DistanceError> tryFromMeters({
    required double meters,
  }) {
    // Sorrend: előbb az isFinite (NaN/infinity), aztán a non-negative.
    // Egy NaN-input nem mehet a `< 0` ellenőrzésen át (NaN minden
    // összehasonlítás false-ot ad), ezért az isFinite-vel zárjuk ki.
    if (!meters.isFinite) {
      return Err(DistanceNotFinite(value: meters));
    }
    if (meters < 0) {
      return Err(DistanceNegative(value: meters));
    }
    return Ok(Distance(meters: meters));
  }

  /// Távolság méterben. Konstruktortól függően nem feltétlenül validált
  /// (lásd [Distance.new]).
  final double meters;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Distance && other.meters == meters;

  @override
  int get hashCode => meters.hashCode;

  @override
  String toString() => 'Distance(m: $meters)';
}

/// A [Distance.tryFromMeters] hibakód-típusa. Sealed, hogy a hívó
/// pattern matching-gel minden esetet kötelezően kezeljen.
@immutable
sealed class DistanceError {
  /// Csak a [DistanceNotFinite] és [DistanceNegative] subclass-ok hívják.
  const DistanceError();
}

/// A megadott érték NaN vagy ±infinity — nem véges számábrázolás.
@immutable
final class DistanceNotFinite extends DistanceError {
  /// Hibainfó: a bemeneti [value] (NaN vagy ±∞).
  const DistanceNotFinite({required this.value});

  /// A bemeneti érték (NaN vagy ±infinity).
  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistanceNotFinite && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DistanceNotFinite(value: $value)';
}

/// A megadott érték negatív — a Distance mindig non-negatív (>= 0).
@immutable
final class DistanceNegative extends DistanceError {
  /// Hibainfó: a bemeneti [value] (< 0).
  const DistanceNegative({required this.value});

  /// A bemeneti érték (negatív).
  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistanceNegative && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DistanceNegative(value: $value)';
}
