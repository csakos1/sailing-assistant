/// Az Excel-napló fejlécei, pontosan a `Versenyek` lap feliratai (ADR 0048
/// D7, Addendum 6 M2, M8).
library;

/// A verseny (első) napja.
const String legacyDateColumn = 'Dátum';

/// A verseny neve.
const String legacyNameColumn = 'Verseny';

/// A YS-szám.
const String legacyYsColumn = 'YS szám';

/// Az osztály-helyezés.
const String legacyClassPlaceColumn = 'Oszt. helyezés';

/// Az abszolút helyezés (kétnapos versenynél az 1. nap).
const String legacyOverallPlaceColumn = 'Abszolút helyezés';

/// Az abszolút helyezés a 2. napon.
const String legacyOverallSecondDayColumn = 'Abszolút 2. nap';

/// Az egytestű helyezés (kétnapos versenynél az 1. nap).
const String legacyMonohullPlaceColumn = 'Egytestű helyezés';

/// Az egytestű helyezés a 2. napon.
const String legacyMonohullSecondDayColumn = 'Egytestű 2. nap';

/// Az abszolút mezőny.
const String legacyFleetColumn = 'Mezőny (hajó)';

/// A hivatalos rajt.
const String legacyStartColumn = 'Rajt';

/// A hivatalos befutás, vagy `DNF`.
const String legacyFinishColumn = 'Befutás';

/// A táv tengeri mérföldben.
const String legacyDistanceColumn = 'Táv (NM)';

/// A max. sebesség csomóban.
const String legacyMaxSpeedColumn = 'Max seb. (kn)';

/// Az átlagos szél csomóban.
const String legacyAvgWindColumn = 'Átl. szél (kn)';

/// A max. szél csomóban.
const String legacyMaxWindColumn = 'Max szél (kn)';

/// Az uralkodó szélirány az Excel 16 jelölésével.
const String legacyWindPointColumn = 'Szélirány';

/// A díj vagy megjegyzés.
const String legacyPrizeColumn = 'Díj / megjegyzés';

/// Az importált oszlopok. Mind kötelező fejléc: ha egy hiányzik, az
/// oszlop adata hang nélkül elveszne.
const Set<String> legacyImportedColumns = {
  legacyDateColumn,
  legacyNameColumn,
  legacyYsColumn,
  legacyClassPlaceColumn,
  legacyOverallPlaceColumn,
  legacyOverallSecondDayColumn,
  legacyMonohullPlaceColumn,
  legacyMonohullSecondDayColumn,
  legacyFleetColumn,
  legacyStartColumn,
  legacyFinishColumn,
  legacyDistanceColumn,
  legacyMaxSpeedColumn,
  legacyAvgWindColumn,
  legacyMaxWindColumn,
  legacyWindPointColumn,
  legacyPrizeColumn,
};

/// A szándékosan kihagyott oszlopok (M2): képletek és a megszűnt mezők.
const Set<String> legacyIgnoredColumns = {
  'Év',
  'Osztály',
  'Dobogó',
  'Menetidő',
  'Átlag (kn)',
  'Telemetria forrása',
};

/// A fejlécek ellenőrzése: az ismeretlen fejléc adata nem importálódna,
/// a hiányzó importált fejléc egy egész oszlopot hagyna ki. Bármelyik
/// esetén az `--apply` nem fut.
({List<String> unknown, List<String> missing}) checkLegacyColumns(
  List<String> columns,
) => (
  unknown: [
    for (final column in columns)
      if (!legacyImportedColumns.contains(column) &&
          !legacyIgnoredColumns.contains(column))
        column,
  ],
  missing: [
    for (final column in legacyImportedColumns)
      if (!columns.contains(column)) column,
  ],
);
