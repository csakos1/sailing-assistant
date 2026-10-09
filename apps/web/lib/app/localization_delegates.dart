import 'package:flutter/widgets.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/l10n/web_localizations.dart';

/// A web összes lokalizációs delegátora (ADR 0047 Addendum 5 F4).
///
/// A web saját ARB-je mellett a `foretack_ui` közös widgetjeinek szövegei a
/// package saját l10n-jéből jönnek. Egyetlen konstans, hogy a `MaterialApp`
/// és minden widget-teszt ugyanazt a listát kapja (a phone mintája).
const List<LocalizationsDelegate<dynamic>> webLocalizationsDelegates = [
  ForetackUiLocalizations.delegate,
  ...WebLocalizations.localizationsDelegates,
];
