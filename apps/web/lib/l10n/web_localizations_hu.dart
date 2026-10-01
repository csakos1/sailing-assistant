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
}
