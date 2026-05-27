// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'Foretack';

  @override
  String get viewerTitle => 'Nyers NMEA folyam';

  @override
  String get viewerEmptyState => 'Még nem érkezett sor.';

  @override
  String get statusConnecting => 'Csatlakozás…';

  @override
  String get statusConnected => 'Csatlakozva';

  @override
  String get statusDisconnected => 'Nincs kapcsolat';

  @override
  String statusError(String message) {
    return 'Hiba: $message';
  }
}
