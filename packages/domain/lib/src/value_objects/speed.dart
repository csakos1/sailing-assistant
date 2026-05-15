import 'package:meta/meta.dart';
import 'package:shared/shared.dart';

/// Egy sebesség, méter/másodpercben mérve.
///
/// Immutable value object. A [metersPerSecond] mező mindig **non-negatív**
/// (>= 0) és véges. A 0 = drift / lehorgonyzott / szélcsend. SI
/// alapegységben (m/s) tárol; csomó, km/h és mph formázás a presentation
/// rétegben történik.
///
/// **Tudatosan unsigned.** A fizikai konvenció szerint **speed = skalár,
/// velocity = vektor**; itt skalárt modellezünk, az irányt a kapcsolódó
/// `Angle` vagy `Bearing` mező adja meg (pl. `WindData.apparentSpeed` +
/// `WindData.apparentAngle`). A "negatív szélsebesség" fogalmilag
/// értelmetlen, és a NMEA 2000 PGN 128259 mezői is unsigned-ek, így a
/// hardver soha nem ad negatív értéket. Ha valaha kell irányított
/// sebesség (anchor drag, reverse motoring, velocity component), az
/// külön value object lesz saját szemantikával.
///
/// Háromféle létrehozási mód, eltérő bizalmi szintekre:
///
/// - [Speed.new] (default const): nincs runtime validáció. Csak akkor
///   használd, ha a hívó garantálja az érvényességet (const literál,
///   vagy belső számítás eredménye, pl. parser).
/// - [Speed.checked]: programozói hibára szabott. NaN, ±infinity vagy
///   negatív érték esetén [ArgumentError]-t dob.
/// - [Speed.tryFromMetersPerSecond]: untrusted bemenethez. NaN/±infinity
///   esetén [SpeedNotFinite]; negatív esetén [SpeedNegative].
@immutable
class Speed {
  /// Default const konstruktor — nincs validáció. Csak garantáltan
  /// érvényes input esetén használd (pl. const literál vagy belső
  /// számítás eredménye).
  const Speed({required this.metersPerSecond});

  /// Programozói hiba védőhálója: NaN, ±infinity vagy negatív érték
  /// esetén [ArgumentError]-t dob.
  factory Speed.checked({required double metersPerSecond}) {
    final result = Speed.tryFromMetersPerSecond(
      metersPerSecond: metersPerSecond,
    );
    return switch (result) {
      Ok(value: final speed) => speed,
      Err(error: final err) => throw ArgumentError(err.toString()),
    };
  }

  /// Untrusted bemenet biztonságos validációja. NaN vagy ±infinity esetén
  /// [SpeedNotFinite]; negatív érték esetén [SpeedNegative].
  static Result<Speed, SpeedError> tryFromMetersPerSecond({
    required double metersPerSecond,
  }) {
    // Sorrend: előbb az isFinite (NaN/infinity), aztán a non-negative.
    // Egy NaN-input nem mehet a `< 0` ellenőrzésen át (NaN minden
    // összehasonlítás false-ot ad), ezért az isFinite-vel zárjuk ki.
    if (!metersPerSecond.isFinite) {
      return Err(SpeedNotFinite(value: metersPerSecond));
    }
    if (metersPerSecond < 0) {
      return Err(SpeedNegative(value: metersPerSecond));
    }
    return Ok(Speed(metersPerSecond: metersPerSecond));
  }

  /// Sebesség m/s-ban. Konstruktortól függően nem feltétlenül validált
  /// (lásd [Speed.new]).
  final double metersPerSecond;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Speed && other.metersPerSecond == metersPerSecond;

  @override
  int get hashCode => metersPerSecond.hashCode;

  @override
  String toString() => 'Speed(m/s: $metersPerSecond)';
}

/// A [Speed.tryFromMetersPerSecond] hibakód-típusa. Sealed, hogy a hívó
/// pattern matching-gel minden esetet kötelezően kezeljen.
@immutable
sealed class SpeedError {
  /// Csak a [SpeedNotFinite] és [SpeedNegative] subclass-ok hívják.
  const SpeedError();
}

/// A megadott érték NaN vagy ±infinity — nem véges számábrázolás.
@immutable
final class SpeedNotFinite extends SpeedError {
  /// Hibainfó: a bemeneti [value] (NaN vagy ±∞).
  const SpeedNotFinite({required this.value});

  /// A bemeneti érték (NaN vagy ±infinity).
  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SpeedNotFinite && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'SpeedNotFinite(value: $value)';
}

/// A megadott érték negatív — a Speed mindig non-negatív (>= 0).
@immutable
final class SpeedNegative extends SpeedError {
  /// Hibainfó: a bemeneti [value] (< 0).
  const SpeedNegative({required this.value});

  /// A bemeneti érték (negatív).
  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SpeedNegative && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'SpeedNegative(value: $value)';
}
