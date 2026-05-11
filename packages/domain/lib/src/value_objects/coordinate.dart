import 'package:meta/meta.dart';
import 'package:shared/shared.dart';

/// Földrajzi pozíció WGS84 referenciakerethez.
///
/// Immutable value object. A [latitude] -90..90 fok, a [longitude]
/// -180..180 fok, mindkét intervallum zárt (a pólusok és az
/// anti-meridián is érvényes). NaN és ±infinity nem fogadható el.
///
/// Háromféle létrehozási mód, eltérő bizalmi szintekre:
///
/// - [Coordinate.new] (default const): nincs runtime validáció.
///   Csak akkor használd, ha a hívó garantálja az érvényességet
///   (pl. const literál, vagy belső, már validált adat).
/// - [Coordinate.checked]: programozói hibára szabott; [ArgumentError]-t
///   dob ha az input érvénytelen. Asszertív kontraktus.
/// - [Coordinate.tryFromDegrees]: untrusted bemenethez; [Result]-ot ad
///   vissza, így a hívó pattern matching-gel kötelezően kezel minden
///   hibás esetet (NMEA parser, CSV import, user input).
@immutable
class Coordinate {
  /// Default konstruktor — nincs runtime validáció. Csak garantáltan
  /// érvényes input esetén használd (pl. konstans, már validált adat).
  const Coordinate({required this.latitude, required this.longitude});

  /// Programozói hiba védőhálója: érvénytelen input esetén
  /// [ArgumentError]-t dob. A hívó implicit kontraktusa hogy a lat/lon
  /// érvényes — ha mégsem, az bug, és gyorsan jelez.
  factory Coordinate.checked({
    required double latitude,
    required double longitude,
  }) {
    final result = Coordinate.tryFromDegrees(
      latitude: latitude,
      longitude: longitude,
    );
    return switch (result) {
      Ok(value: final coord) => coord,
      Err(error: final err) => throw ArgumentError(err.toString()),
    };
  }

  /// Untrusted bemenet biztonságos validációja. A hívó `switch`-csel
  /// kötelezően lekezeli mindkét ágat — érvénytelen input nem dob,
  /// hanem [CoordinateError]-ral tér vissza.
  static Result<Coordinate, CoordinateError> tryFromDegrees({
    required double latitude,
    required double longitude,
  }) {
    if (!latitude.isFinite) {
      return Err(CoordinateNotFinite(field: 'latitude', value: latitude));
    }
    if (!longitude.isFinite) {
      return Err(CoordinateNotFinite(field: 'longitude', value: longitude));
    }
    if (latitude < -90 || latitude > 90) {
      return Err(CoordinateOutOfRange(field: 'latitude', value: latitude));
    }
    if (longitude < -180 || longitude > 180) {
      return Err(CoordinateOutOfRange(field: 'longitude', value: longitude));
    }
    return Ok(Coordinate(latitude: latitude, longitude: longitude));
  }

  /// Földrajzi szélesség, -90..90 fok.
  final double latitude;

  /// Földrajzi hosszúság, -180..180 fok.
  final double longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coordinate &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'Coordinate(lat: $latitude, lon: $longitude)';
}

/// A [Coordinate.tryFromDegrees] hibakód-típusa. Sealed, hogy a hívó
/// pattern matching-gel minden esetet kötelezően kezeljen.
@immutable
sealed class CoordinateError {
  /// Csak a [CoordinateOutOfRange] és [CoordinateNotFinite] subclass-ok hívják.
  const CoordinateError();
}

/// A megadott mező értéke a megengedett intervallumon kívül esik
/// (latitude: -90..90, longitude: -180..180).
@immutable
final class CoordinateOutOfRange extends CoordinateError {
  /// Hibainfó: melyik mező ([field]) milyen [value]-val.
  const CoordinateOutOfRange({required this.field, required this.value});

  /// `'latitude'` vagy `'longitude'`.
  final String field;

  /// A bemeneti érték, amit nem fogadtunk el.
  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoordinateOutOfRange &&
          other.field == field &&
          other.value == value;

  @override
  int get hashCode => Object.hash(field, value);

  @override
  String toString() => 'CoordinateOutOfRange(field: $field, value: $value)';
}

/// A megadott mező NaN vagy ±infinity — nem véges számábrázolás.
@immutable
final class CoordinateNotFinite extends CoordinateError {
  /// Hibainfó: melyik mező ([field]) milyen [value]-val (NaN vagy ±∞).
  const CoordinateNotFinite({required this.field, required this.value});

  /// `'latitude'` vagy `'longitude'`.
  final String field;

  /// A bemeneti érték (NaN vagy ±infinity).
  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoordinateNotFinite &&
          other.field == field &&
          other.value == value;

  @override
  int get hashCode => Object.hash(field, value);

  @override
  String toString() => 'CoordinateNotFinite(field: $field, value: $value)';
}
