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
  String get editTimeHint => 'ÓÓ:PP';

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
  String get editProblemTime => 'Hibás idő, pl. 10:00.';

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
}
