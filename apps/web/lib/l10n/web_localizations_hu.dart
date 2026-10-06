// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'web_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class WebLocalizationsHu extends WebLocalizations {
  WebLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'Foretack archívum';

  @override
  String get logTitle => 'Versenynapló';

  @override
  String logMonth(DateTime month) {
    final intl.DateFormat monthDateFormat = intl.DateFormat.MMMM(localeName);
    final String monthString = monthDateFormat.format(month);

    return '$monthString';
  }

  @override
  String logRaceCountCaps(int count) {
    return '$count VERSENY';
  }

  @override
  String get logAllYearsCaps => 'ÖSSZES';

  @override
  String logYearRange(int first, int last) {
    return '$first–$last';
  }

  @override
  String get logStatTimeCaps => 'VÍZEN TÖLTÖTT';

  @override
  String get logStatDistanceCaps => 'ÖSSZ. TÁV';

  @override
  String get logStatRecordCaps => 'REKORD';

  @override
  String get logLoadError =>
      'Nem sikerült betölteni a versenyeket. Az adat nem veszett el, csak most nem érhető el.';

  @override
  String get logRetryCaps => 'ÚJRA';

  @override
  String get logEmpty =>
      'Még nincs verseny az archívumban. Tölts fel egy telefonos adatbázist, vagy vegyél fel egy versenyt kézzel.';

  @override
  String get detailLoadError =>
      'Nem sikerült betölteni a versenyt. Az adat nem veszett el, csak most nem érhető el.';

  @override
  String get detailNotFound => 'Ez a verseny már nincs az archívumban.';

  @override
  String get detailManualCaps => 'KÉZI RÖGZÍTÉS';

  @override
  String get detailWindAvgCaps => 'ÁTL. SZÉL';

  @override
  String get detailWindMaxCaps => 'MAX SZÉL';

  @override
  String get detailWindDirectionCaps => 'SZÉLIRÁNY';

  @override
  String get detailApproximate =>
      '~ Közelítő értékek a teljes rögzítésből. A hivatalos rajttal és befutással a versenyablakra pontosodnak.';

  @override
  String get detailResultCaps => 'EREDMÉNY';

  @override
  String get detailNoResult => 'Eredmény még nincs rögzítve.';

  @override
  String get detailClassPlaceCaps => 'OSZTÁLY';

  @override
  String get detailOverallPlaceCaps => 'ABSZOLÚT';

  @override
  String get detailMonohullPlaceCaps => 'EGYTESTŰ';

  @override
  String get detailYsCaps => 'YS-SZÁM';

  @override
  String get detailOfficialStartCaps => 'HIVATALOS RAJT';

  @override
  String get detailOfficialFinishCaps => 'HIVATALOS BEFUTÁS';

  @override
  String get detailElapsedCaps => 'MENETIDŐ';

  @override
  String get detailNextDayCaps => '+1 NAP';

  @override
  String get detailPrizeCaps => 'DÍJ';

  @override
  String get detailMarksCaps => 'BÓJÁK';

  @override
  String get detailSummaryCaps => 'ÖSSZEFOGLALÓ';

  @override
  String get detailTrackEmpty => 'Nincs track-adat ehhez a versenyhez.';

  @override
  String get detailTrackOpenFullscreen => 'Track nagyítása';

  @override
  String get detailTrackLegendTitle => 'sebesség (kn)';

  @override
  String get detailTrackLegendUnknown => 'nincs adat';

  @override
  String get detailEditTooltip => 'Szerkesztés';

  @override
  String get editResultTitle => 'Eredmény szerkesztése';

  @override
  String get editSave => 'Mentés';

  @override
  String get editTelemetryReadOnlyCaps => 'A TELEFON ADATA · NEM SZERKESZTHETŐ';

  @override
  String editRecordingCaps(String date, String start, String end) {
    return '$date · RÖGZÍTÉS $start – $end';
  }

  @override
  String get editSectionResultCaps => 'EREDMÉNY';

  @override
  String get editSectionTimesCaps => 'HIVATALOS IDŐ';

  @override
  String get editSectionPrizeSummaryCaps => 'DÍJ ÉS ÖSSZEFOGLALÓ';

  @override
  String get editClassPlace => 'Osztály';

  @override
  String get editOverallPlace => 'Abszolút';

  @override
  String get editMonohullPlace => 'Egytestű';

  @override
  String get editPlaceFieldCaps => 'HELYEZÉS';

  @override
  String get editFleetFieldCaps => 'MEZŐNY';

  @override
  String get editPlacingNumberCaps => 'SZÁM';

  @override
  String get editPlacingDnfCaps => 'DNF';

  @override
  String get editPlacingDsqCaps => 'DSQ';

  @override
  String get editYs => 'YS-szám';

  @override
  String get editYsFieldCaps => 'YS';

  @override
  String get editYsHint => 'két tizedes, pl. 75,90';

  @override
  String get editOfficialStart => 'Hivatalos rajt';

  @override
  String get editOfficialFinish => 'Hivatalos befutás';

  @override
  String get editDateFieldCaps => 'DÁTUM';

  @override
  String get editDateHint => 'ÉÉÉÉ.HH.NN';

  @override
  String get editTimeFieldCaps => 'IDŐ';

  @override
  String get editTimeHint => 'ÓÓ:PP(:MM)';

  @override
  String get editSameDayCaps => 'AZNAP';

  @override
  String get editNextDayCaps => '+1 NAP';

  @override
  String get editSecondDayCaps => '+2 NAP';

  @override
  String get editElapsed => 'Menetidő';

  @override
  String get editComputedCaps => 'SZÁMOLT';

  @override
  String get editElapsedSourceCaps => 'A HIVATALOS RAJTBÓL ÉS BEFUTÁSBÓL';

  @override
  String get editPrize => 'Díj';

  @override
  String get editPrizeFieldCaps => 'RÖVID SZÖVEG';

  @override
  String get editPrizeHint => 'pl. érem, kupa, Hungária pezsgő';

  @override
  String get editSummary => 'Összefoglaló';

  @override
  String get editSummaryFieldCaps => 'SIMA SZÖVEG';

  @override
  String get editSummaryHint =>
      'Hogyan ment a verseny? Szél, taktika, tanulságok…';

  @override
  String get editProblemWholeNumber => 'Csak pozitív egész szám írható ide.';

  @override
  String get editProblemDecimal => 'Szám kell, pl. 10,2.';

  @override
  String get editProblemYs => 'Két tizedes kell, pl. 75,90.';

  @override
  String get editProblemDate => 'Hibás dátum, pl. 2026.06.13.';

  @override
  String get editProblemTime => 'Hibás idő, pl. 10:00 vagy 10:00:30.';

  @override
  String get editProblemPlaceAtLeastOne => 'A helyezés legalább 1.';

  @override
  String get editProblemFleetAtLeastOne => 'A mezőny legalább 1.';

  @override
  String get editProblemYsAtLeastOne => 'A YS-szám nem lehet nulla.';

  @override
  String editProblemPlaceExceedsFleet(String fleetSize) {
    return 'A helyezés nem lehet nagyobb a mezőnynél ($fleetSize).';
  }

  @override
  String get editProblemFinishNotAfterStart =>
      'A befutás nem későbbi a rajtnál. Másnap értetek be? Válaszd a +1 NAP-ot.';

  @override
  String get editProblemNegative => 'Nem lehet negatív.';

  @override
  String get editProblemRequired => 'Kötelező mező.';

  @override
  String get editProblemAtLeastOne => 'Az érték legalább 1.';

  @override
  String get editSaveFailed =>
      'A mentés nem sikerült. A változtatások megmaradtak, próbáld újra.';

  @override
  String get editRaceGone => 'Ez a verseny már nincs az archívumban.';

  @override
  String get editDiscardTitle => 'Elveted a változtatásokat?';

  @override
  String get editDiscardMessage =>
      'A módosításokat nem mentetted. Ha most kilépsz, elvesznek.';

  @override
  String get editDiscardKeep => 'Folytatom';

  @override
  String get editDiscardConfirm => 'Elvetés';

  @override
  String get snackResultSaved => 'Eredmény mentve';

  @override
  String get logNewRace => 'Új verseny';

  @override
  String get newRaceTitle => 'Új verseny';

  @override
  String get editManualTitle => 'Verseny szerkesztése';

  @override
  String get editDeleteTooltip => 'Verseny törlése';

  @override
  String get editManualCaps => 'KÉZI VERSENY';

  @override
  String get editManualNoTelemetryCaps =>
      'TELEMETRIA NÉLKÜL · NINCS TÉRKÉP ÉS BÓJA';

  @override
  String get editSectionRaceCaps => 'VERSENY';

  @override
  String get editName => 'Név';

  @override
  String get editRequiredCaps => 'KÖTELEZŐ';

  @override
  String get editNameFieldCaps => 'NÉV';

  @override
  String get editNameHint => 'pl. 57. Kékszalag (nyílt)';

  @override
  String get editDate => 'Dátum';

  @override
  String get editSectionDistanceWindCaps => 'TÁV ÉS SZÉL';

  @override
  String get editDistanceSpeed => 'Táv és sebesség';

  @override
  String get editDistanceFieldCaps => 'TÁV · KM';

  @override
  String get editMaxKnotsFieldCaps => 'MAX · KN';

  @override
  String get editAvgSpeed => 'Átlagsebesség';

  @override
  String get editAvgSpeedSourceCaps => 'TÁVBÓL ÉS MENETIDŐBŐL SZÁMOLVA';

  @override
  String editKnotsValue(String value) {
    return '$value kn';
  }

  @override
  String get editWind => 'Szél';

  @override
  String get editAvgKnotsFieldCaps => 'ÁTLAG · KN';

  @override
  String get editWindDirection => 'Szélirány';

  @override
  String get editWindDirectionNone => 'nincs megadva';

  @override
  String get editWindFromCaps => 'HONNAN FÚJ';

  @override
  String get editDeleteTitle => 'Törlöd a versenyt?';

  @override
  String get editDeleteMessage =>
      'A kézi verseny minden adata törlődik az archívumból. A törlés végleges, nem vonható vissza.';

  @override
  String get editDeleteCancel => 'Mégse';

  @override
  String get editDeleteConfirm => 'Törlés';

  @override
  String get editDeleteRowRace => 'Verseny';

  @override
  String get editDeleteRowDate => 'Dátum';

  @override
  String get editDeleteFailed => 'A törlés nem sikerült. Próbáld újra.';

  @override
  String get snackRaceSaved => 'Verseny mentve';

  @override
  String get snackRaceCreated => 'Verseny létrehozva';

  @override
  String get snackRaceDeleted => 'Verseny törölve';

  @override
  String get logUpload => 'Feltöltés';

  @override
  String get importTitle => 'Adatbázis feltöltése';

  @override
  String get importMessage =>
      'A telefon Foretack-adatbázisa. A befejezett versenyek bekerülnek a naplóba, a már meglévők frissülnek.';

  @override
  String get importDatabaseLabelCaps => 'ADATBÁZIS · KÖTELEZŐ';

  @override
  String get importWalLabelCaps => 'WAL-FÁJL · OPCIONÁLIS';

  @override
  String get importNoFile => 'Nincs kiválasztva';

  @override
  String get importBrowseCaps => 'TALLÓZÁS';

  @override
  String get importReplaceCaps => 'CSERE';

  @override
  String get importWalHint =>
      'A -wal fájl a legutóbbi verseny adatainak egy részét hordozhatja, ezért érdemes azt is feltölteni.';

  @override
  String get importCancel => 'Mégse';

  @override
  String get importStart => 'Feltöltés';

  @override
  String get importUploading => 'Feltöltés…';

  @override
  String importPercent(int percent) {
    return '$percent %';
  }

  @override
  String get importProcessingCaps => 'FELDOLGOZÁS';

  @override
  String get importDoneTitle => 'Feltöltés kész';

  @override
  String get importDoneMessage => 'A napló a bezáráskor frissül.';

  @override
  String get importWalIgnored =>
      'A WAL-fájl érvénytelen volt, ezért csak a fő fájl adatai kerültek be.';

  @override
  String get importNothingFound => 'A fájlban nem volt verseny.';

  @override
  String get importGroupAdded => 'Új';

  @override
  String get importGroupUpdated => 'Frissült';

  @override
  String get importGroupSkipped => 'Kimaradt · nem befejezett';

  @override
  String importRaceDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get importClose => 'Bezárás';

  @override
  String get importSchemaTitle => 'Az app újabb adatbázis-verziót használ';

  @override
  String get importSchemaMessage =>
      'Frissítsd a szervert, és töltsd fel újra a fájlt. A napló nem változott.';

  @override
  String get importSchemaServer => 'Szerver';

  @override
  String importSchemaVersionCaps(int version) {
    return 'SÉMA v$version';
  }

  @override
  String get importFailedNetwork =>
      'A feltöltés megszakadt. Ellenőrizd a kapcsolatot, és próbáld újra.';

  @override
  String get importFailedNotSqlite =>
      'A kiválasztott fájl nem SQLite-adatbázis.';

  @override
  String get importFailedNotForetack =>
      'A kiválasztott fájl nem a Foretack adatbázisa.';

  @override
  String get importFailedMainFileMissing =>
      'A fő adatbázis-fájl nem érkezett meg. Válaszd ki újra, és próbáld újra.';

  @override
  String importFailedTooLarge(String limit) {
    return 'A fájl nagyobb a szerver korlátjánál ($limit).';
  }

  @override
  String get importFailedServer =>
      'A szerver nem tudta feldolgozni a fájlt. Próbáld újra később.';

  @override
  String get logViewList => 'Lista';

  @override
  String get logViewTable => 'Táblázat';

  @override
  String get logViewToggleLabel => 'Napló nézete';

  @override
  String get tableGroupRaceCaps => 'VERSENY';

  @override
  String get tableGroupResultCaps => 'EREDMÉNY · HELYEZÉS/MEZŐNY';

  @override
  String get tableGroupTimeCaps => 'IDŐ ÉS TÁV';

  @override
  String get tableGroupSpeedCaps => 'SEBESSÉG ÉS SZÉL';

  @override
  String get tableGroupPrizeCaps => 'DÍJ';

  @override
  String get tableColumnDateCaps => 'DÁTUM';

  @override
  String get tableColumnNameCaps => 'VERSENY';

  @override
  String get tableColumnClassCaps => 'OSZT.';

  @override
  String get tableColumnOverallCaps => 'ABSZ.';

  @override
  String get tableColumnMonohullCaps => 'EGYT.';

  @override
  String get tableColumnYsCaps => 'YS';

  @override
  String get tableColumnStartCaps => 'RAJT';

  @override
  String get tableColumnFinishCaps => 'BEFUTÁS';

  @override
  String get tableColumnElapsedCaps => 'MENETIDŐ';

  @override
  String get tableColumnDistanceCaps => 'TÁV';

  @override
  String get tableColumnAvgSpeedCaps => 'ÁTLAG';

  @override
  String get tableColumnMaxSpeedCaps => 'MAX';

  @override
  String get tableColumnAvgWindCaps => 'ÁTL. SZÉL';

  @override
  String get tableColumnMaxWindCaps => 'MAX SZÉL';

  @override
  String get tableColumnDirectionCaps => 'IRÁNY';

  @override
  String get tableColumnPrizeCaps => 'DÍJ';

  @override
  String get tableManualCaps => 'KÉZI';

  @override
  String get tableNextDay => '+1';

  @override
  String tableSortedAscending(String column) {
    return '$column, növekvő sorrend';
  }

  @override
  String tableSortedDescending(String column) {
    return '$column, csökkenő sorrend';
  }

  @override
  String get tableUnitKilometers => 'km';

  @override
  String get tableUnitKnots => 'kn';

  @override
  String get tableUnitClock => 'ó:p';

  @override
  String get tableUnitElapsed => 'ó:p:mp';

  @override
  String get editStatsFromTrackNote =>
      'A táv, a sebesség és a szél a régi trackből számolódik, a hivatalos rajt és befutás között.';

  @override
  String get editAvgSpeedTrackSourceCaps => 'A TRACKBŐL SZÁMOLVA';

  @override
  String get logStatistics => 'Statisztika';

  @override
  String get logExport => 'Export';

  @override
  String get statsTitle => 'Statisztika';

  @override
  String get statsStatRacesCaps => 'VERSENY';

  @override
  String get statsColumnPodiumCaps => 'DOBOGÓS';

  @override
  String get statsWindBandsCaps => 'ÁTLAGSZÉL SZERINT';

  @override
  String statsWindBandBelow(int high) {
    return '< $high kn';
  }

  @override
  String statsWindBandRange(int low, int high) {
    return '$low–$high kn';
  }

  @override
  String statsWindBandAbove(int low) {
    return '≥ $low kn';
  }

  @override
  String get statsColumnYearCaps => 'ÉV';

  @override
  String get statsSeasonCaps => 'AZ ÉVAD';

  @override
  String get statsPodiumRacesCaps => 'DOBOGÓS VERSENY';

  @override
  String get statsPodiumRateCaps => 'DOBOGÓS ARÁNY';

  @override
  String get statsPodiumPlacingsCaps => 'DOBOGÓS HELYEZÉS';

  @override
  String get statsClassCaps => 'OSZTÁLYBAN';

  @override
  String get statsOverallCaps => 'ABSZOLÚT';

  @override
  String get statsFirstPlaceCaps => 'I. HELY';

  @override
  String get statsSecondPlaceCaps => 'II. HELY';

  @override
  String get statsThirdPlaceCaps => 'III. HELY';

  @override
  String statsOfStarts(int total) {
    return 'a $total indulásból';
  }

  @override
  String get statsOffPodium => 'Dobogón kívül:';

  @override
  String get statsTrackCaps => 'A PÁLYÁN';

  @override
  String get statsLongestRaceCaps => 'LEGHOSSZABB TÁV';

  @override
  String get statsAverageSpeedCaps => 'ÁTLAGSEBESSÉG';

  @override
  String get statsFastestAverageCaps => 'LEGGYORSABB VERSENY';

  @override
  String get statsTopSpeedCaps => 'CSÚCSSEBESSÉG';

  @override
  String get statsStrongestWindCaps => 'LEGERŐSEBB SZÉL';

  @override
  String get statsPrevailingWindCaps => 'URALKODÓ SZÉLIRÁNY';

  @override
  String get statsMedalTableCaps => 'ÉREMTÁBLA ÉVENKÉNT';

  @override
  String get statsColumnStartsCaps => 'INDULÁS';

  @override
  String get statsColumnHarvestCaps => 'AZ ÉV TERMÉSE';

  @override
  String get statsTotalRow => 'Össz.';

  @override
  String get statsHarvestTotal => 'dobogós helyezés';

  @override
  String get polarSeasonSectionCaps => 'POLÁR-TELJESÍTMÉNY';

  @override
  String polarSeasonTrailing(int count) {
    return '$count verseny · időrendben';
  }

  @override
  String get polarYearsSectionCaps => 'POLÁR ÉVENKÉNT';

  @override
  String polarYearsTrailing(int count) {
    return 'időre súlyozva · $count verseny';
  }

  @override
  String get polarGroupPercentCaps => 'POLÁR %';

  @override
  String get polarGroupTimeCaps => 'AZ IDŐ %';

  @override
  String get polarColumnYearCaps => 'ÉV';

  @override
  String get polarColumnRankCaps => 'RANG';

  @override
  String get polarColumnDateCaps => 'DÁTUM';

  @override
  String get polarColumnRaceCaps => 'VERSENY';

  @override
  String get polarColumnWindCaps => 'SZÉL';

  @override
  String get polarColumnAverageCaps => 'ÁTLAG';

  @override
  String get polarColumnMedianCaps => 'MEDIÁN';

  @override
  String get polarColumnP90Caps => 'P90';

  @override
  String get polarColumnP99Caps => 'P99';

  @override
  String get polarColumnBestCaps => 'LEGJOBB';

  @override
  String get polarColumnBestUnitCaps => '5 MP';

  @override
  String get polarColumnAbove90Caps => '90%';

  @override
  String get polarColumnAbove100Caps => '100%';

  @override
  String get polarColumnAboveUnitCaps => 'FELETT';

  @override
  String get polarRankTooltip => 'Szélvödrökre standardizált átlag';

  @override
  String get polarApproximateTooltip =>
      'Közelítő: nincs hivatalos rajt és befutás, a teljes rögzítésből';

  @override
  String get polarYearRacesSuffix => 'vers.';

  @override
  String get polarRaceAverage => 'A futamok átlaga';

  @override
  String get polarTimeWeighted => 'Időre súlyozva';

  @override
  String polarMeasuredHours(String hours) {
    return '$hours ó mért idő';
  }

  @override
  String get polarFootnote =>
      'A százalék a mért vízsebesség (STW) és a polár célsebességének aránya az adott szélszögre és -erősségre. A 100% nem plafon, hanem a historikus felső tized küszöbe.';

  @override
  String get polarFewData => 'kevés adat';

  @override
  String get polarNotComputed => 'még nincs számolva';

  @override
  String get polarStale =>
      'Újraszámolás a szerveren — a korábbi értékek látszanak.';

  @override
  String get polarUnavailable =>
      'Nincs polár a szerveren, ezért teljesítmény-százalék nem számolható.';

  @override
  String get polarLoadError => 'A polár-adatok nem tölthetők be.';

  @override
  String get polarDetailCaps => 'POLÁR';

  @override
  String get polarDetailApproximateCaps => '≈ KÖZELÍTŐ';

  @override
  String get polarDetailFewDataCaps => 'KEVÉS ADAT';

  @override
  String get polarDetailRankCaps => 'SZEZONBELI RANG';

  @override
  String polarDetailRankOf(int count) {
    return '/ $count';
  }

  @override
  String get polarDetailBestCaps => 'LEGJOBB 5 MP';

  @override
  String get polarDetailAbove90Caps => '90% FELETT';

  @override
  String get polarDetailAbove100Caps => '100% FELETT';
}
