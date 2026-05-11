import 'package:meta/meta.dart';

/// Egy művelet eredménye: vagy [Ok] sikerrel, vagy [Err] hibával.
///
/// A Result típus a dobott exception alternatívája olyan határoknál, ahol
/// a "rossz bemenet" várt eset és nem programozói hiba: NMEA parsing,
/// CSV import, felhasználói bevitel validációja. A hívó kötelezően
/// kezel mindkét ágat, jellemzően `switch` pattern matching-gel.
///
/// Példa:
/// ```dart
/// final result = parseCoordinate(input);
/// switch (result) {
///   case Ok(value: final coord): useCoordinate(coord);
///   case Err(error: final err): showWarning(err);
/// }
/// ```
@immutable
sealed class Result<T, E> {
  /// Csak az [Ok] és [Err] subclass-ok hívják.
  const Result();
}

/// A művelet sikeres eredménye — a hordozott érték a [value].
@immutable
final class Ok<T, E> extends Result<T, E> {
  /// Sikeres eredményt csomagol.
  const Ok(this.value);

  /// A művelet által visszaadott érték.
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Ok<T, E> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ok($value)';
}

/// A művelet hibás eredménye — a hordozott hibainfó az [error].
@immutable
final class Err<T, E> extends Result<T, E> {
  /// Hibás eredményt csomagol.
  const Err(this.error);

  /// A művelet által generált hiba.
  final E error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Err<T, E> && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Err($error)';
}
