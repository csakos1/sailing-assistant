import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_server/src/legacy/decode_legacy_sheet.dart';
import 'package:web_server/src/legacy/legacy_cell.dart';
import 'package:web_server/src/legacy/legacy_sheet.dart';
import 'package:web_server/src/legacy/legacy_sheet_row.dart';

String _document(List<Object?> rows) => jsonEncode({
  'format': legacySheetFormatName,
  'version': legacySheetFormatVersion,
  'sheet': 'Versenyek',
  'columns': ['Dátum', 'Verseny'],
  'rows': rows,
});

void main() {
  group('decodeLegacySheet', () {
    test('decodes every cell type by its header', () {
      // ARRANGE
      final source = _document([
        {
          'row': 64,
          'cells': {
            'Verseny': {'type': 'text', 'value': 'Mihálkovics'},
            'YS szám': {'type': 'number', 'value': 75.9},
            'Mezőny (hajó)': {'type': 'number', 'value': 181},
            'Rajt': {'type': 'datetime', 'value': '2026-06-13T10:00:00'},
            'Menetidő': {'type': 'duration', 'value': 19854.0},
          },
        },
      ]);

      // ACT
      final result = decodeLegacySheet(source);

      // ASSERT
      expect(
        result,
        isA<Ok<LegacySheet, LegacySheetFormatError>>().having(
          (ok) => ok.value,
          'value',
          LegacySheet(
            columns: const ['Dátum', 'Verseny'],
            rows: [
              LegacySheetRow(
                rowNumber: 64,
                cells: {
                  'Verseny': const LegacyText('Mihálkovics'),
                  'YS szám': const LegacyNumber(75.9),
                  'Mezőny (hajó)': const LegacyNumber(181),
                  'Rajt': LegacyDateTime(DateTime.utc(2026, 6, 13, 10)),
                  'Menetidő': const LegacyDuration(19854),
                },
              ),
            ],
          ),
        ),
      );
    });

    test('keeps the fraction of a second in a time cell', () {
      // ARRANGE
      final source = _document([
        {
          'row': 3,
          'cells': {
            'Befutás': {'type': 'datetime', 'value': '2021-05-15T15:47:58.84'},
          },
        },
      ]);

      // ACT
      final result = decodeLegacySheet(source);

      // ASSERT
      final row =
          (result as Ok<LegacySheet, LegacySheetFormatError>).value.rows.single;
      expect(
        row.cells['Befutás'],
        LegacyDateTime(DateTime.utc(2021, 5, 15, 15, 47, 58, 840)),
      );
    });

    test('rejects text that is not JSON', () {
      // ACT
      final result = decodeLegacySheet('not json');

      // ASSERT
      expect(result, isA<Err<LegacySheet, LegacySheetFormatError>>());
    });

    test('rejects a document without the header list', () {
      // ARRANGE
      final source = jsonEncode({
        'format': legacySheetFormatName,
        'version': legacySheetFormatVersion,
        'rows': <Object?>[],
      });

      // ACT
      final result = decodeLegacySheet(source);

      // ASSERT
      expect(result, isA<Err<LegacySheet, LegacySheetFormatError>>());
    });

    test('rejects another format or version', () {
      // ARRANGE
      final source = jsonEncode({
        'format': legacySheetFormatName,
        'version': 2,
        'columns': <Object?>[],
        'rows': <Object?>[],
      });

      // ACT
      final result = decodeLegacySheet(source);

      // ASSERT
      expect(result, isA<Err<LegacySheet, LegacySheetFormatError>>());
    });

    test('rejects an unknown cell type', () {
      // ARRANGE
      final source = _document([
        {
          'row': 3,
          'cells': {
            'Verseny': {'type': 'formula', 'value': '=A1'},
          },
        },
      ]);

      // ACT
      final result = decodeLegacySheet(source);

      // ASSERT
      expect(result, isA<Err<LegacySheet, LegacySheetFormatError>>());
    });

    test('rejects a date that does not exist', () {
      // ARRANGE
      final source = _document([
        {
          'row': 3,
          'cells': {
            'Dátum': {'type': 'datetime', 'value': '2026-02-30T00:00:00'},
          },
        },
      ]);

      // ACT
      final result = decodeLegacySheet(source);

      // ASSERT
      expect(result, isA<Err<LegacySheet, LegacySheetFormatError>>());
    });
  });
}
