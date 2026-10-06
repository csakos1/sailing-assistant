import 'package:domain/domain.dart';
import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:shared/shared.dart';

/// Belső jelzés: a dekódolás egy [DecodeError]-ral elakadt.
///
/// Csak a [JsonReader] dobja és csak a [runDecode] kapja el, így a kivétel
/// soha nem hagyja el a csomagot: kifelé minden dekóder `Result`-ot ad
/// (ADR 0047 Addendum 1 A2). A mélyen beágyazott olvasásnál ez olcsóbb és
/// olvashatóbb, mint minden szinten `Result`-ot továbbadni.
final class DecodeFailure implements Exception {
  /// A dekódolás a megadott [error]-ral akadt el.
  const DecodeFailure(this.error);

  /// A hiba helye és oka.
  final DecodeError error;
}

/// A [decode]-ot futtatja, és a [DecodeFailure]-t `Err`-ré alakítja.
///
/// Más kivételt nem fog el: az programozói hiba, nem rossz bemenet.
Result<T, DecodeError> runDecode<T>(T Function() decode) {
  try {
    return Ok(decode());
  } on DecodeFailure catch (failure) {
    return Err(failure.error);
  }
}

/// Típusos olvasó egy JSON-objektum fölött, útvonal-követéssel.
///
/// Minden olvasó metódus vagy a kért típusú értéket adja, vagy
/// [DecodeFailure]-t dob a mező teljes útvonalával.
final class JsonReader {
  JsonReader._(this._map, this._path);

  /// Olvasó a dokumentum gyökerére (`$`).
  factory JsonReader.root(Object? json) => JsonReader.at(json, r'$');

  /// Olvasó a [path] útvonalon álló [json] objektumra.
  factory JsonReader.at(Object? json, String path) {
    if (json is Map<String, Object?>) return JsonReader._(json, path);
    throw DecodeFailure(DecodeError(path: path, expected: 'object'));
  }

  // A JS-ben ábrázolható legnagyobb DateTime-érték (±8.64e15 ms): ezen
  // túl a DateTime konstruktor RangeError-t dobna, ami nem várt bemenet,
  // hanem hibás bemenet.
  static const int _maxEpochMillis = 8640000000000000;

  final Map<String, Object?> _map;
  final String _path;

  /// Ennek az objektumnak az útvonala.
  String get path => _path;

  /// A [key] mező útvonala.
  String childPath(String key) => '$_path.$key';

  /// Hiba ennek az objektumnak a szintjén (pl. érvénytelen koordináta-pár).
  Never failHere(String expected) =>
      throw DecodeFailure(DecodeError(path: _path, expected: expected));

  /// Hiba a [path] útvonalon — tömb-elemekhez, amelyek nem objektumok.
  static Never failAt(String path, String expected) =>
      throw DecodeFailure(DecodeError(path: path, expected: expected));

  Never _fail(String key, String expected) => failAt(childPath(key), expected);

  /// Kötelező szöveg.
  String string(String key) {
    final value = _map[key];
    if (value is String) return value;
    _fail(key, 'string');
  }

  /// Kötelező, nem üres szöveg.
  String nonEmptyString(String key) {
    final value = _map[key];
    if (value is String && value.isNotEmpty) return value;
    _fail(key, 'non-empty string');
  }

  /// Opcionális szöveg (`null` vagy hiányzó mező → `null`).
  String? optionalString(String key) {
    return switch (_map[key]) {
      null => null,
      final String value => value,
      _ => _fail(key, 'string or null'),
    };
  }

  /// Kötelező logikai érték.
  bool boolean(String key) {
    final value = _map[key];
    if (value is bool) return value;
    _fail(key, 'boolean');
  }

  /// Kötelező egész szám.
  int integer(String key) => _asInt(_map[key]) ?? _fail(key, 'integer');

  /// Kötelező egész szám, legalább [min].
  int integerAtLeast(String key, int min) {
    final value = _asInt(_map[key]);
    if (value != null && value >= min) return value;
    _fail(key, 'integer >= $min');
  }

  /// Opcionális egész szám.
  int? optionalInteger(String key) {
    final value = _map[key];
    if (value == null) return null;
    return _asInt(value) ?? _fail(key, 'integer or null');
  }

  /// Kötelező véges szám.
  double number(String key) => _asDouble(_map[key]) ?? _fail(key, 'number');

  /// Opcionális véges szám.
  double? optionalNumber(String key) {
    final value = _map[key];
    if (value == null) return null;
    return _asDouble(value) ?? _fail(key, 'number or null');
  }

  /// Kötelező UTC időbélyeg epoch-milliszekundumból.
  DateTime utcMillis(String key) {
    final millis = _asInt(_map[key]);
    if (millis != null && millis.abs() <= _maxEpochMillis) {
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
    _fail(key, 'epoch milliseconds');
  }

  /// Opcionális UTC időbélyeg epoch-milliszekundumból.
  DateTime? optionalUtcMillis(String key) {
    if (_map[key] == null) return null;
    return utcMillis(key);
  }

  /// Opcionális, nem negatív időtartam milliszekundumból.
  Duration? optionalDurationMillis(String key) {
    final value = _map[key];
    if (value == null) return null;
    final millis = _asInt(value);
    if (millis != null && millis >= 0) return Duration(milliseconds: millis);
    _fail(key, 'non-negative milliseconds or null');
  }

  /// Kötelező beágyazott objektum.
  JsonReader object(String key) => JsonReader.at(_map[key], childPath(key));

  /// Opcionális beágyazott objektum.
  JsonReader? optionalObject(String key) {
    final value = _map[key];
    if (value == null) return null;
    return JsonReader.at(value, childPath(key));
  }

  /// Kötelező tömb; minden elemét a [decodeItem] olvassa, az elem
  /// útvonalával (`...[i]`).
  List<T> list<T>(
    String key,
    T Function(Object? item, String path) decodeItem,
  ) {
    final value = _map[key];
    if (value is! List<Object?>) _fail(key, 'array');
    final listPath = childPath(key);
    return [
      for (var i = 0; i < value.length; i++)
        decodeItem(value[i], '$listPath[$i]'),
    ];
  }

  /// Opcionális tömb: a hiányzó kulcs és a `null` is `null`; különben a
  /// [list] szerint olvas.
  List<T>? optionalList<T>(
    String key,
    T Function(Object? item, String path) decodeItem,
  ) => _map[key] == null ? null : list(key, decodeItem);

  /// Kötelező enum-érték a `name`-je alapján.
  T enumByName<T extends Enum>(String key, List<T> values) {
    final name = _map[key];
    for (final value in values) {
      if (value.name == name) return value;
    }
    _fail(key, 'one of ${values.map((value) => value.name).join('|')}');
  }

  /// Opcionális enum-érték a `name`-je alapján (`null` vagy hiányzó mező →
  /// `null`).
  T? optionalEnumByName<T extends Enum>(String key, List<T> values) {
    if (_map[key] == null) return null;
    return enumByName(key, values);
  }

  /// Opcionális érték, amely egész szám vagy a [symbols] szövegek egyike:
  /// `int`, `String` vagy `null`. Például a helyezés (`3`, `"dnf"`).
  Object? optionalIntegerOrSymbol(String key, Set<String> symbols) {
    final value = _map[key];
    if (value == null) return null;
    if (value is String && symbols.contains(value)) return value;
    final integer = _asInt(value);
    if (integer != null) return integer;
    _fail(key, 'integer, ${symbols.map((s) => '"$s"').join(', ')} or null');
  }

  /// Kötelező koordináta (`{lat, lon}`), a domain tartomány-ellenőrzésével.
  Coordinate coordinate(String key) {
    final reader = object(key);
    final result = Coordinate.tryFromDegrees(
      latitude: reader.number('lat'),
      longitude: reader.number('lon'),
    );
    return switch (result) {
      Ok(value: final coordinate) => coordinate,
      Err() => reader.failHere('coordinate within range'),
    };
  }

  static int? _asInt(Object? value) {
    return switch (value) {
      final int integer => integer,
      // A web-en (JS) minden szám double; a jsonDecode ott egész értéket
      // is double-ként adhat, ezt egésznek fogadjuk el.
      final double real when real.isFinite && real == real.truncateToDouble() =>
        real.toInt(),
      _ => null,
    };
  }

  static double? _asDouble(Object? value) {
    return switch (value) {
      final num number when number.isFinite => number.toDouble(),
      _ => null,
    };
  }
}
