import 'package:web_server/src/legacy/legacy_cell.dart';
import 'package:web_server/src/legacy/legacy_sheet_row.dart';

// Excel-sor fixturak a normalizalo es a tervezo tesztjeihez. A fejlecek
// pontosan az Excel feliratai.

/// Egy sor a [date] napra, a [name] nevvel es a tovabbi [cells]
/// cellakkal.
LegacySheetRow legacyRow({
  required int rowNumber,
  DateTime? date,
  String name = 'Teszt verseny',
  Map<String, LegacyCell> cells = const {},
}) => LegacySheetRow(
  rowNumber: rowNumber,
  cells: {
    'Dátum': LegacyDateTime(date ?? DateTime.utc(2025, 6, 14)),
    'Verseny': LegacyText(name),
    ...cells,
  },
);

/// Falora-ido cella.
LegacyDateTime wallClock(
  int year,
  int month,
  int day, [
  int hour = 0,
  int minute = 0,
  int second = 0,
]) => LegacyDateTime(DateTime.utc(year, month, day, hour, minute, second));
