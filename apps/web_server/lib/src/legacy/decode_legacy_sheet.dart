import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/legacy/legacy_cell.dart';
import 'package:web_server/src/legacy/legacy_sheet.dart';
import 'package:web_server/src/legacy/legacy_sheet_row.dart';

/// A kinyerő formátumának neve és verziója (ADR 0048 Addendum 6 M8).
const String legacySheetFormatName = 'foretack-legacy-race-log';

/// A támogatott formátum-verzió.
const int legacySheetFormatVersion = 1;

/// A kinyerő JSON-ja nem a várt alakú.
final class LegacySheetFormatError extends Equatable {
  /// Hiba a [detail] leírással.
  const LegacySheetFormatError(this.detail);

  /// Mi a hiba, a CLI kiírásához.
  final String detail;

  @override
  List<Object?> get props => [detail];
}

/// A `xlsx_to_json.py` kimenetének fejlécei és sorai (ADR 0048 D7,
/// Addendum 6 M8).
///
/// Pure. A hibás alakot `Result`-tal jelzi, mert a fájl külső eszközből
/// jön; kivételt nem dob.
Result<LegacySheet, LegacySheetFormatError> decodeLegacySheet(
  String source,
) {
  final Object? document;
  try {
    document = jsonDecode(source);
  } on FormatException catch (error) {
    return Err(LegacySheetFormatError('nem JSON: ${error.message}'));
  }
  if (document is! Map<String, Object?>) {
    return const Err(LegacySheetFormatError('a gyökér nem objektum'));
  }
  if (document['format'] != legacySheetFormatName ||
      document['version'] != legacySheetFormatVersion) {
    return const Err(
      LegacySheetFormatError(
        'nem a $legacySheetFormatName v$legacySheetFormatVersion formátum',
      ),
    );
  }
  final columns = document['columns'];
  if (columns is! List<Object?> || columns.any((column) => column is! String)) {
    return const Err(LegacySheetFormatError('hiányzik a „columns" lista'));
  }
  final rows = document['rows'];
  if (rows is! List<Object?>) {
    return const Err(LegacySheetFormatError('hiányzik a „rows" lista'));
  }
  final decoded = <LegacySheetRow>[];
  for (final (index, row) in rows.indexed) {
    switch (_decodeRow(row)) {
      case Ok(:final value):
        decoded.add(value);
      case Err(:final error):
        return Err(LegacySheetFormatError('${index + 1}. sor: $error'));
    }
  }
  return Ok(LegacySheet(columns: columns.cast<String>(), rows: decoded));
}

Result<LegacySheetRow, String> _decodeRow(Object? row) {
  if (row is! Map<String, Object?>) return const Err('nem objektum');
  final rowNumber = row['row'];
  final cells = row['cells'];
  if (rowNumber is! int || rowNumber < 1) return const Err('rossz sorszám');
  if (cells is! Map<String, Object?>) return const Err('hiányzó cellák');
  final decoded = <String, LegacyCell>{};
  for (final MapEntry(:key, :value) in cells.entries) {
    final cell = _decodeCell(value);
    if (cell == null) return Err('olvashatatlan cella: „$key"');
    decoded[key] = cell;
  }
  return Ok(LegacySheetRow(rowNumber: rowNumber, cells: decoded));
}

LegacyCell? _decodeCell(Object? cell) {
  if (cell is! Map<String, Object?>) return null;
  final value = cell['value'];
  return switch ((cell['type'], value)) {
    ('text', final String text) => LegacyText(text),
    ('number', final num number) => LegacyNumber(number.toDouble()),
    ('duration', final num seconds) => LegacyDuration(seconds.toDouble()),
    ('datetime', final String text) => switch (_parseWallClock(text)) {
      null => null,
      final wallClock => LegacyDateTime(wallClock),
    },
    _ => null,
  };
}

// A Python `isoformat()`-ja zóna nélkül: `2026-06-13T10:00:00`, tört
// másodperccel `…:58.840000`. A `DateTime.parse` ezt helyi időként
// olvasná, és a gép zónája elnormalizálhatná a mezőket, ezért kézzel.
final RegExp _wallClockPattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,6}))?$',
);

DateTime? _parseWallClock(String text) {
  final match = _wallClockPattern.firstMatch(text);
  if (match == null) return null;
  // A minta hat kötelező csoportja számjegy, ezért a `!` és a parse
  // biztonságos; a hetedik (tört másodperc) opcionális.
  int part(int group) => int.parse(match.group(group)!);
  final fraction = (match.group(7) ?? '').padRight(6, '0');
  final parsed = DateTime.utc(
    part(1),
    part(2),
    part(3),
    part(4),
    part(5),
    part(6),
    0,
    int.parse(fraction),
  );
  // A DateTime a túlcsorduló mezőt továbbgörgeti; a nem létező dátum hiba.
  final isExact =
      parsed.year == part(1) &&
      parsed.month == part(2) &&
      parsed.day == part(3) &&
      parsed.hour == part(4) &&
      parsed.minute == part(5) &&
      parsed.second == part(6);
  return isExact ? parsed : null;
}
