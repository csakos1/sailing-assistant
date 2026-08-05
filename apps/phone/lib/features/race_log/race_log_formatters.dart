import 'package:phone/features/race_detail/track_stats_formatters.dart';

/// A vízen töltött idő a napló stat-csíkjához (ADR 0044 D42).
///
/// A `MeasuredValue` alakot követi, mint a `measureKnots` és a
/// `measureDistance`: az értéket és a mértékegységet két külön
/// tipográfia-fokozat rajzolja (D29), tehát egyetlen stringként nem
/// használható.
///
/// Egy óra alatt percre vált, tizedes nélkül — egy 45 perces szezon
/// `0,8 ó` alakban elveszítené a felbontását, ugyanaz a megfontolás, ami a
/// `measureDistance` km/m váltását indokolja. Fölötte órában, egy
/// tizedesre: egy szezon hossza óra-pontossággal érdekes, perccel már
/// zajos lenne.
///
/// A `null` a hiányzó mérés, nem a nulla: a `Duration.zero` valós érték
/// (`0 p`), a `null` viszont a hiányjelet kapja, és **mértékegység nélkül**
/// — egy gondolatjel mellett az `ó` azt sugallná, hogy mértünk valamit.
MeasuredValue measureHours(Duration? elapsed) {
  if (elapsed == null) {
    return (value: missingValueLabel, unit: '');
  }
  if (elapsed.inMinutes < 60) {
    return (value: '${elapsed.inMinutes}', unit: 'p');
  }
  return (value: _withDecimalComma(elapsed.inMinutes / 60, 1), unit: 'ó');
}

// A magyar tizedesvessző. A `track_stats_formatters.dart` privát
// megfelelőjét nem lehet importálni; ha egy harmadik helyen is kellene,
// az a jele, hogy a formázókat közös könyvtárba kell emelni.
String _withDecimalComma(double value, int digits) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');
