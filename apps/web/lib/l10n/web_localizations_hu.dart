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
}
