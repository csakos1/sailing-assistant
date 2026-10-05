import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/legacy/budapest_time.dart';
import 'package:web_server/src/legacy/legacy_cell.dart';
import 'package:web_server/src/legacy/legacy_row_problem.dart';
import 'package:web_server/src/legacy/legacy_sheet_row.dart';

/// Egy Excel-sor celláinak típusos olvasója (ADR 0048 Addendum 6 M2).
///
/// Minden olvasó `null`-t ad, ha a cella üres vagy hibás; a hibát a
/// [problems], a tájékoztató átírást a [notes] gyűjti. Így a sor minden
/// hibája egy körben kiderül, nem csak az első.
final class LegacyRowReader {
  /// Olvasó a [_row] sorhoz.
  LegacyRowReader(this._row);

  final LegacySheetRow _row;
  final List<LegacyRowProblem> _problems = [];
  final List<String> _notes = [];

  /// Az eddig talált hibák.
  List<LegacyRowProblem> get problems => List.unmodifiable(_problems);

  /// Az eddigi tájékoztató megjegyzések.
  List<String> get notes => List.unmodifiable(_notes);

  /// Kötelező szöveg, levágva; üresen `missing` hiba.
  String? requiredText(String column) {
    final text = optionalText(column);
    if (text == null && !_hasProblemIn(column)) {
      _problems.add(
        LegacyRowProblem(column: column, kind: LegacyProblemKind.missing),
      );
    }
    return text;
  }

  /// Opcionális szöveg, levágva; az üres szöveg `null`.
  String? optionalText(String column) {
    final cell = _row.cells[column];
    if (cell == null) return null;
    if (cell is! LegacyText) return _unreadable(column, cell);
    final text = cell.text.trim();
    return text.isEmpty ? null : text;
  }

  /// Kötelező naptári nap egy dátum-cellából.
  CalendarDate? requiredDate(String column) {
    final cell = _row.cells[column];
    if (cell == null) {
      _problems.add(
        LegacyRowProblem(column: column, kind: LegacyProblemKind.missing),
      );
      return null;
    }
    if (cell is! LegacyDateTime) return _unreadable(column, cell);
    final wallClock = cell.wallClock;
    return CalendarDate.tryFromParts(
      year: wallClock.year,
      month: wallClock.month,
      day: wallClock.day,
    );
  }

  /// Opcionális szám.
  double? number(String column) {
    final cell = _row.cells[column];
    if (cell == null) return null;
    if (cell is! LegacyNumber) return _unreadable(column, cell);
    return cell.value;
  }

  /// Opcionális egész szám; a törtszám hiba.
  int? wholeNumber(String column) {
    final value = number(column);
    if (value == null) return null;
    if (value != value.roundToDouble()) {
      return _unreadable(column, LegacyNumber(value));
    }
    return value.round();
  }

  /// Igaz, ha a cellában a [marker] szöveg áll (kis- és nagybetű, szélek
  /// nélkül), pl. a Befutás `DNF`-je.
  bool hasMarker(String column, String marker) {
    final cell = _row.cells[column];
    return cell is LegacyText &&
        cell.text.trim().toUpperCase() == marker.toUpperCase();
  }

  /// Opcionális helyezés (M2): szám, `19.`, `8. / 6.`, DNF, DNC, DSQ.
  Placing? placing(String column) {
    final cell = _row.cells[column];
    switch (cell) {
      case null:
        return null;
      case LegacyNumber(:final value):
        return _placingFromNumber(column, value);
      case LegacyText(:final text):
        return _placingFromText(column, text);
      case LegacyDateTime() || LegacyDuration():
        return _unreadable(column, cell);
    }
  }

  /// Opcionális helyi (Europe/Budapest) idő UTC-pillanatként, egész
  /// másodpercre kerekítve (M2, M3).
  ///
  /// A [skippedMarker] szöveg (pl. `DNF`) nem hiba, csak nincs idő.
  DateTime? instant(String column, {String? skippedMarker}) {
    final cell = _row.cells[column];
    switch (cell) {
      case null:
        return null;
      case LegacyDateTime(:final wallClock):
        return budapestWallClockToUtc(_roundedToSecond(wallClock));
      case LegacyText(:final text):
        if (skippedMarker != null && hasMarker(column, skippedMarker)) {
          return null;
        }
        final wallClock = _wallClockFromText(text);
        if (wallClock == null) return _unreadable(column, cell);
        return budapestWallClockToUtc(wallClock);
      case LegacyNumber() || LegacyDuration():
        return _unreadable(column, cell);
    }
  }

  /// Opcionális égtáj az Excel 16 jelöléséből (ADR 0048 D5).
  CompassPoint? compassPoint(String column) {
    final text = optionalText(column);
    if (text == null) return null;
    final point = legacyCompassPointsByLabel[text];
    if (point == null) return _unreadable(column, LegacyText(text));
    return point;
  }

  Placing? _placingFromNumber(String column, double value) {
    if (value != value.roundToDouble()) {
      return _unreadable(column, LegacyNumber(value));
    }
    final place = value.round();
    // A negatív szám az Excelben jelölés volt, a helyezés az
    // abszolútértéke (felhasználói döntés, M2).
    if (place < 0) _notes.add('$column: $place → ${-place}');
    return FinishPlace(place.abs());
  }

  Placing? _placingFromText(String column, String text) {
    final trimmed = text.trim();
    switch (trimmed.toUpperCase()) {
      case 'DNF' || 'DNC':
        return const Dnf();
      case 'DSQ':
        return const Dsq();
    }
    final single = _singlePlacePattern.firstMatch(trimmed);
    if (single != null) return FinishPlace(int.parse(single.group(1)!));
    final pair = _placePairPattern.firstMatch(trimmed);
    if (pair != null) {
      final first = int.parse(pair.group(1)!);
      _notes.add('$column: „$trimmed" → $first');
      return FinishPlace(first);
    }
    return _unreadable(column, LegacyText(text));
  }

  bool _hasProblemIn(String column) =>
      _problems.any((problem) => problem.column == column);

  // Mindig `null`-t ad, hogy a hívó egy lépésben jelezhessen és
  // térhessen vissza; a típust a hívó visszatérési típusa adja.
  T? _unreadable<T>(String column, LegacyCell cell) {
    _problems.add(
      LegacyRowProblem(
        column: column,
        kind: LegacyProblemKind.unreadable,
        detail: _describe(cell),
      ),
    );
    return null;
  }
}

// `19.` és `19`.
final RegExp _singlePlacePattern = RegExp(r'^(\d+)\.?$');

// `8. / 6.`: a 58. Kékszalag egytestű cellája (ADR 0048 D7).
final RegExp _placePairPattern = RegExp(r'^(\d+)\.?\s*/\s*(\d+)\.?$');

// `2025.05.25 12:00`, `2026.07.18. 11:00`, `2026.07.30. 9:00`, opcionális
// másodperccel.
final RegExp _textTimePattern = RegExp(
  r'^(\d{4})\.\s?(\d{1,2})\.\s?(\d{1,2})\.?\s+(\d{1,2}):(\d{2})(?::(\d{2}))?$',
);

DateTime? _wallClockFromText(String text) {
  final match = _textTimePattern.firstMatch(text.trim());
  if (match == null) return null;
  // Az első öt csoport kötelező és csupa számjegy, ezért a `!` biztonságos.
  final fields = [
    for (var group = 1; group <= 5; group++) int.parse(match.group(group)!),
    int.parse(match.group(6) ?? '0'),
  ];
  final wallClock = DateTime.utc(
    fields[0],
    fields[1],
    fields[2],
    fields[3],
    fields[4],
    fields[5],
  );
  // A DateTime a túlcsorduló mezőt görgeti; a nem létező idő hiba.
  final isExact =
      wallClock.month == fields[1] &&
      wallClock.day == fields[2] &&
      wallClock.hour == fields[3] &&
      wallClock.minute == fields[4] &&
      wallClock.second == fields[5];
  return isExact ? wallClock : null;
}

// Az Excel időcellái tört másodpercet is hordozhatnak (`…:58.840000`).
DateTime _roundedToSecond(DateTime wallClock) {
  final truncated = DateTime.utc(
    wallClock.year,
    wallClock.month,
    wallClock.day,
    wallClock.hour,
    wallClock.minute,
    wallClock.second,
  );
  final fraction = wallClock.difference(truncated);
  return fraction >= const Duration(milliseconds: 500)
      ? truncated.add(const Duration(seconds: 1))
      : truncated;
}

String _describe(LegacyCell cell) => switch (cell) {
  LegacyText(:final text) => '„$text"',
  LegacyNumber(:final value) => '$value',
  LegacyDateTime(:final wallClock) => wallClock.toIso8601String(),
  LegacyDuration(:final seconds) => '$seconds mp',
};

/// Az Excel szélirány-jelölései, pontosan az ADR 0048 D5 listája
/// szerint.
const Map<String, CompassPoint> legacyCompassPointsByLabel = {
  'É': CompassPoint.north,
  'ÉÉK': CompassPoint.northNorthEast,
  'ÉK': CompassPoint.northEast,
  'KÉK': CompassPoint.eastNorthEast,
  'K': CompassPoint.east,
  'KDK': CompassPoint.eastSouthEast,
  'DK': CompassPoint.southEast,
  'DDK': CompassPoint.southSouthEast,
  'D': CompassPoint.south,
  'DDNy': CompassPoint.southSouthWest,
  'DNy': CompassPoint.southWest,
  'NyDNy': CompassPoint.westSouthWest,
  'Ny': CompassPoint.west,
  'NyÉNy': CompassPoint.westNorthWest,
  'ÉNy': CompassPoint.northWest,
  'ÉÉNy': CompassPoint.northNorthWest,
};
