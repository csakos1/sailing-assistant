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
}
