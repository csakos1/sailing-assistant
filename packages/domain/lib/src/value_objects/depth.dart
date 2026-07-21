import 'package:meta/meta.dart';
import 'package:shared/shared.dart';

/// A víz mélysége méterben, a jeladó (DST P617V triducer) alatt mérve.
///
/// Immutable value object. A [meters] mező mindig **non-negatív** (>= 0)
/// és véges. A `Speed` mintáját követi: skalár mennyiség, SI
/// alapegységben tárolva; a megjelenítési formázás (láb, öl) a
/// presentation réteg dolga.
///
/// **A nyers, JELADÓ-ALATTI mélységet tárolja, offset NÉLKÜL** (ADR 0031
/// D2). A `DPT` mondat offset-mezőjét (tőkesúly- vagy vízfelszín-
/// korrekció) a v1 tudatosan nem számolja bele: a 2,5 m-es riasztási
/// küszöb ehhez a nyers értékhez van hangolva. Az offsetes, valódi
/// tőkesúly-alatti mélység v2-finomítás.
///
/// Háromféle létrehozási mód, eltérő bizalmi szintekre:
///
/// - [Depth.new] (default const): nincs runtime validáció. Csak akkor
///   használd, ha a hívó garantálja az érvényességet (const literál vagy
///   belső számítás eredménye).
/// - [Depth.checked]: programozói hibára szabott. NaN, ±infinity vagy
///   negatív érték esetén [ArgumentError]-t dob.
/// - [Depth.tryFromMeters]: untrusted NMEA-bemenethez. NaN/±infinity
///   esetén [DepthNotFinite]; negatív esetén [DepthNegative].
@immutable
class Depth {
  /// Default const konstruktor — nincs validáció. Csak garantáltan
  /// érvényes input esetén használd.
  const Depth({required this.meters});

  /// Programozói hiba védőhálója: NaN, ±infinity vagy negatív érték
  /// esetén [ArgumentError]-t dob.
  factory Depth.checked({required double meters}) {
    final result = Depth.tryFromMeters(meters: meters);
    return switch (result) {
      Ok(value: final depth) => depth,
      Err(error: final err) => throw ArgumentError(err.toString()),
    };
  }

  /// Untrusted bemenet biztonságos validációja. NaN vagy ±infinity
  /// esetén [DepthNotFinite]; negatív érték esetén [DepthNegative].
  static Result<Depth, DepthError> tryFromMeters({
    required double meters,
  }) {
    // Sorrend: előbb az isFinite (NaN/infinity), aztán a non-negative. A
    // NaN minden összehasonlításra false-ot ad, ezért a `< 0` ágon nem
    // akadna fenn.
    if (!meters.isFinite) {
      return Err(DepthNotFinite(value: meters));
    }
    if (meters < 0) {
      return Err(DepthNegative(value: meters));
    }
    return Ok(Depth(meters: meters));
  }

  /// A mért mélység méterben, a jeladó alatt. Konstruktortól függően nem
  /// feltétlenül validált (lásd [Depth.new]).
  final double meters;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Depth && other.meters == meters;

  @override
  int get hashCode => meters.hashCode;

  @override
  String toString() => 'Depth(m: $meters)';
}

/// A [Depth.tryFromMeters] hibakód-típusa. Sealed, hogy a hívó pattern
/// matching-gel minden esetet kötelezően kezeljen.
@immutable
sealed class DepthError {
  /// Csak a [DepthNotFinite] és [DepthNegative] subclass-ok hívják.
  const DepthError();
}

/// A megadott érték NaN vagy ±infinity — nem véges számábrázolás.
@immutable
final class DepthNotFinite extends DepthError {
  /// Hibainfó: a bemeneti [value] (NaN vagy ±∞).
  const DepthNotFinite({required this.value});

  /// A bemeneti érték (NaN vagy ±infinity).
  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DepthNotFinite && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DepthNotFinite(value: $value)';
}

/// A megadott érték negatív — a Depth mindig non-negatív (>= 0).
@immutable
final class DepthNegative extends DepthError {
  /// Hibainfó: a bemeneti [value] (< 0).
  const DepthNegative({required this.value});

  /// A bemeneti érték (negatív).
  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DepthNegative && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DepthNegative(value: $value)';
}
