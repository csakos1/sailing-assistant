import 'package:flutter/widgets.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A phone összes lokalizációs delegátora (ADR 0047 Addendum 5 F4).
///
/// A phone saját ARB-je mellett a `foretack_ui` közös widgetjeinek
/// szövegei a package saját l10n-jéből jönnek. Egyetlen konstans, hogy a
/// `MaterialApp` és minden widget-teszt ugyanazt a listát kapja: így egy
/// később költöző widget nem tör el egy tesztet sem azzal, hogy egy
/// delegátor kimaradt a tesztből.
const List<LocalizationsDelegate<dynamic>> phoneLocalizationsDelegates = [
  ForetackUiLocalizations.delegate,
  ...AppLocalizations.localizationsDelegates,
];
