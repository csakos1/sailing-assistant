import 'package:test/test.dart';
import 'package:web_server/src/legacy/legacy_columns.dart';

// A Versenyek lap valodi fejlecei, balrol jobbra.
const _sheetColumns = [
  'Év',
  'Dátum',
  'Verseny',
  'Osztály',
  'YS szám',
  'Oszt. helyezés',
  'Abszolút helyezés',
  'Abszolút 2. nap',
  'Egytestű helyezés',
  'Egytestű 2. nap',
  'Mezőny (hajó)',
  'Dobogó',
  'Rajt',
  'Befutás',
  'Menetidő',
  'Táv (NM)',
  'Átlag (kn)',
  'Max seb. (kn)',
  'Átl. szél (kn)',
  'Max szél (kn)',
  'Szélirány',
  'Díj / megjegyzés',
  'Telemetria forrása',
];

void main() {
  group('checkLegacyColumns', () {
    test('accepts the headers of the real sheet', () {
      // ACT
      final check = checkLegacyColumns(_sheetColumns);

      // ASSERT
      expect(check.unknown, isEmpty);
      expect(check.missing, isEmpty);
    });

    test('reports a renamed header as unknown and missing', () {
      // ARRANGE
      final columns = [
        for (final column in _sheetColumns)
          column == 'Max seb. (kn)' ? 'Max sebesség (kn)' : column,
      ];

      // ACT
      final check = checkLegacyColumns(columns);

      // ASSERT
      expect(check.unknown, ['Max sebesség (kn)']);
      expect(check.missing, ['Max seb. (kn)']);
    });
  });
}
