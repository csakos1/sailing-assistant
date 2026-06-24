import 'package:meta/meta.dart';
import 'package:shared/shared.dart';

/// Földrajzi tengely a [ParseGeoAngle] számára. Megszabja az elfogadott
/// égtáj-betűket (szélesség: N/S, hosszúság: E/W) és a végső, előjeles
/// fok-tartományt (szélesség: -90..90, hosszúság: -180..180).
enum GeoAxis {
  /// Földrajzi szélesség: N/S betűk, -90..90 fok.
  latitude,

  /// Földrajzi hosszúság: E/W betűk, -180..180 fok.
  longitude,
}

/// A [ParseGeoAngle] hibakód-típusa. Sealed, hogy a hívó (a race-setup
/// validátora) pattern matchinggel minden ágat kötelezően lekezeljen, és
/// minden levélhez külön, érthető ARB-hibaszöveg tartozhasson.
///
/// Tudatosan KÜLÖN a `CoordinateError`-tól (ISP): a parser a szöveges
/// bevitel szintaktikai hibáit írja le, a `CoordinateError` a kész
/// `Coordinate` érték-tartományi hibáit.
@immutable
sealed class GeoAngleParseError {
  /// Csak a levél-osztályok hívják.
  const GeoAngleParseError();
}

/// A bemenet üres (vagy csak whitespace) — nincs mit értelmezni.
@immutable
final class EmptyInput extends GeoAngleParseError {
  /// Üres-bemenet hibát jelez.
  const EmptyInput();

  @override
  bool operator ==(Object other) => other is EmptyInput;

  @override
  int get hashCode => (EmptyInput).hashCode;

  @override
  String toString() => 'EmptyInput()';
}

/// A bemenet egyik ismert formátumra (DD/DDM/DMS) sem illeszthető:
/// nem-szám komponens, túl sok komponens (pl. teljes "lat, lon" egy
/// mezőben), vagy az égtáj-betűvel ellentmondó explicit előjel.
@immutable
final class Unrecognized extends GeoAngleParseError {
  /// A fel nem ismert, trimmelt nyers bemenet ([input]) — a hibaüzenethez.
  const Unrecognized({required this.input});

  /// A nyers, trimmelt bemenet, amit nem sikerült értelmezni.
  final String input;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Unrecognized && other.input == input;

  @override
  int get hashCode => input.hashCode;

  @override
  String toString() => 'Unrecognized(input: $input)';
}

/// Egy perc- vagy másodperc-komponens a `[0, 60)` tartományon kívül esik.
@immutable
final class ComponentOutOfRange extends GeoAngleParseError {
  /// A hibás komponens neve ([component]: `'minutes'` vagy `'seconds'`) és
  /// a [value]-ja, ami nem fér a `[0, 60)` tartományba.
  const ComponentOutOfRange({required this.component, required this.value});

  /// `'minutes'` vagy `'seconds'`.
  final String component;

  /// A bemeneti érték, ami a `[0, 60)` tartományon kívül esett.
  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentOutOfRange &&
          other.component == component &&
          other.value == value;

  @override
  int get hashCode => Object.hash(component, value);

  @override
  String toString() =>
      'ComponentOutOfRange(component: $component, value: $value)';
}

/// Az égtáj-betű nem illik a tengelyhez (pl. `'E'` a szélesség-mezőben).
@immutable
final class CardinalMismatch extends GeoAngleParseError {
  /// A megadott égtáj-betű ([cardinal]) és a [axis], amelyhez nem illik.
  const CardinalMismatch({required this.cardinal, required this.axis});

  /// A bemeneti égtáj-betű (`'N'`/`'S'`/`'E'`/`'W'`), nagybetűsítve.
  final String cardinal;

  /// A tengely, amelyhez a betű nem illik.
  final GeoAxis axis;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardinalMismatch &&
          other.cardinal == cardinal &&
          other.axis == axis;

  @override
  int get hashCode => Object.hash(cardinal, axis);

  @override
  String toString() => 'CardinalMismatch(cardinal: $cardinal, axis: $axis)';
}

/// A kész, előjeles fok-érték a tengely megengedett tartományán kívül
/// esik (szélesség: -90..90, hosszúság: -180..180).
@immutable
final class OutOfRange extends GeoAngleParseError {
  /// A tartományon kívüli [value] és a [axis], amelynek tartományát sérti.
  const OutOfRange({required this.value, required this.axis});

  /// A kiszámolt, előjeles fok-érték, ami kívül esett.
  final double value;

  /// A tengely, amelynek tartományát az érték megsértette.
  final GeoAxis axis;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutOfRange && other.value == value && other.axis == axis;

  @override
  int get hashCode => Object.hash(value, axis);

  @override
  String toString() => 'OutOfRange(value: $value, axis: $axis)';
}

/// Szöveges földrajzi szög értelmezése előjeles tizedes-fokká.
///
/// Tengelyenként hívandó (egy hívás = egy tengely): a szélesség- és a
/// hosszúság-mezőt külön parse-oljuk. Mindhárom elterjedt formátumot
/// fogadja, toleráns szintaxissal (a `°`/`'`/`"` és az égtáj-betű körüli
/// szóköz opcionális):
///
/// - DD  (tizedes-fok): `46.946554`, `-46.946554`, `46.946554 N`
/// - DDM (fok-perc):    `46° 56.793' N`, `46 56.793 N`
/// - DMS (fok-perc-mp): `46° 56' 47.6" N`, `46 56 47.6 N`
///
/// Előjel-konvenció: `S`/`W` vagy vezető `-` → negatív; `N`/`E` vagy
/// hiányzó betű/jel → pozitív (csupasz szám = N/E, a Balatonra a
/// természetes alapeset). Égtáj-betű ÉS azzal ellentmondó explicit előjel
/// együtt [Unrecognized].
///
/// A use case NEM hív `Coordinate`-et: csak az előjeles `double`-t adja.
/// A végső, kombinált tartomány-kapu továbbra is a `Coordinate.checked`
/// a hívó oldalon (belt-and-suspenders) — itt csak per-tengely range.
final class ParseGeoAngle {
  /// Const ctor — állapotmentes, újrahasználható use case.
  const ParseGeoAngle();

  /// Az [input] szöveget a megadott [axis] szerint előjeles tizedes-fokká
  /// alakítja, vagy a megfelelő [GeoAngleParseError]-t adja vissza.
  Result<double, GeoAngleParseError> call({
    required String input,
    required GeoAxis axis,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const Err(EmptyInput());
    }

    // Az égtáj-betű a string elején vagy végén állhat; leválasztjuk és
    // nagybetűsítjük. A `body` a betű nélküli, jel + szám rész marad.
    String? cardinal;
    var body = trimmed;
    final lastUpper = body[body.length - 1].toUpperCase();
    final firstUpper = body[0].toUpperCase();
    if (_isCardinalLetter(lastUpper)) {
      cardinal = lastUpper;
      body = body.substring(0, body.length - 1).trim();
    } else if (_isCardinalLetter(firstUpper)) {
      cardinal = firstUpper;
      body = body.substring(1).trim();
    }

    // Explicit előjel a szám előtt (a betű leválasztása után).
    bool? explicitNegative;
    if (body.startsWith('-')) {
      explicitNegative = true;
      body = body.substring(1);
    } else if (body.startsWith('+')) {
      explicitNegative = false;
      body = body.substring(1);
    }

    // A fok/perc/mp szeparátorai (°'") és a szóközök egységesítése, majd
    // szám-komponensekre bontás. 1 komponens = DD, 2 = DDM, 3 = DMS.
    final components = body
        .replaceAll('°', ' ')
        .replaceAll("'", ' ')
        .replaceAll('"', ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (components.isEmpty || components.length > 3) {
      return Err(Unrecognized(input: trimmed));
    }
    final values = <double>[];
    for (final part in components) {
      final parsed = double.tryParse(part);
      if (parsed == null) {
        return Err(Unrecognized(input: trimmed));
      }
      values.add(parsed);
    }

    // Perc/mp a `[0, 60)` tartományba kell essen; a fok-komponensre nincs
    // ilyen korlát — azt a végső, előjeles range-kapu fedi le.
    if (values.length >= 2) {
      final minutes = values[1];
      if (minutes < 0 || minutes >= 60) {
        return Err(ComponentOutOfRange(component: 'minutes', value: minutes));
      }
    }
    if (values.length == 3) {
      final seconds = values[2];
      if (seconds < 0 || seconds >= 60) {
        return Err(ComponentOutOfRange(component: 'seconds', value: seconds));
      }
    }

    // A fok-komponens sem lehet negatív: az előjel a betűből/jelből jön,
    // így egy negatív fok-token (pl. dupla mínusz) szintaktikai hiba.
    if (values[0] < 0) {
      return Err(Unrecognized(input: trimmed));
    }

    // Magnitúdó tizedes-fokban, a komponens-számtól függően.
    final magnitude = switch (values.length) {
      1 => values[0],
      2 => values[0] + values[1] / 60,
      _ => values[0] + values[1] / 60 + values[2] / 3600,
    };

    // Az előjel a betűből és/vagy az explicit jelből jön (P7). Ha mindkettő
    // jelen van és ellentmondanak → Unrecognized.
    final cardinalNegative = switch (cardinal) {
      'S' || 'W' => true,
      'N' || 'E' => false,
      _ => null,
    };
    if (cardinalNegative != null &&
        explicitNegative != null &&
        cardinalNegative != explicitNegative) {
      return Err(Unrecognized(input: trimmed));
    }

    // Az égtáj-betű illik-e a tengelyhez (pl. 'E' nem szélesség).
    if (cardinal != null) {
      final fitsAxis = switch (axis) {
        GeoAxis.latitude => cardinal == 'N' || cardinal == 'S',
        GeoAxis.longitude => cardinal == 'E' || cardinal == 'W',
      };
      if (!fitsAxis) {
        return Err(CardinalMismatch(cardinal: cardinal, axis: axis));
      }
    }

    final isNegative = cardinalNegative ?? explicitNegative ?? false;
    final signed = isNegative ? -magnitude : magnitude;

    // Per-tengely range; a Coordinate.checked marad a végső kombinált kapu.
    final limit = axis == GeoAxis.latitude ? 90.0 : 180.0;
    if (signed < -limit || signed > limit) {
      return Err(OutOfRange(value: signed, axis: axis));
    }

    return Ok(signed);
  }

  /// Igaz, ha [c] (nagybetűsítve) érvényes égtáj-betű (N/S/E/W).
  bool _isCardinalLetter(String c) =>
      c == 'N' || c == 'S' || c == 'E' || c == 'W';
}
