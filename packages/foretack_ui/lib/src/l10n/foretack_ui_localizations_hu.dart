// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'foretack_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class ForetackUiLocalizationsHu extends ForetackUiLocalizations {
  ForetackUiLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get listStatusNotStarted => 'NEM INDULT';

  @override
  String get listStatusActive => 'FOLYAMATBAN';

  @override
  String get listStatusFinished => 'BEFEJEZETT';

  @override
  String detailFinishedDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get listNoMarksCaps => 'BÓJA NÉLKÜL';

  @override
  String listMarkCountCaps(int count) {
    return '$count BÓJA';
  }

  @override
  String get detailTrackMaxSpeedCaps => 'MAX SEB.';

  @override
  String get detailTrackAvgSpeedCaps => 'ÁTLAG SEB.';

  @override
  String get detailTrackDistanceCaps => 'TÁV';
}
