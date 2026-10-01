import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'foretack_ui_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ForetackUiLocalizations
/// returned by `ForetackUiLocalizations.of(context)`.
///
/// Applications need to include `ForetackUiLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/foretack_ui_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ForetackUiLocalizations.localizationsDelegates,
///   supportedLocales: ForetackUiLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ForetackUiLocalizations.supportedLocales
/// property.
abstract class ForetackUiLocalizations {
  ForetackUiLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ForetackUiLocalizations? of(BuildContext context) {
    return Localizations.of<ForetackUiLocalizations>(
      context,
      ForetackUiLocalizations,
    );
  }

  static const LocalizationsDelegate<ForetackUiLocalizations> delegate =
      _ForetackUiLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('hu')];

  /// A lajstrom-sor státusz-felirata még nem indult versenynél.
  ///
  /// In hu, this message translates to:
  /// **'NEM INDULT'**
  String get listStatusNotStarted;

  /// A lajstrom-sor státusz-felirata futó versenynél.
  ///
  /// In hu, this message translates to:
  /// **'FOLYAMATBAN'**
  String get listStatusActive;

  /// A befejezett verseny verzál státusz-felirata a detail-képernyő csíkján.
  ///
  /// In hu, this message translates to:
  /// **'BEFEJEZETT'**
  String get listStatusFinished;

  /// A befejezes datuma a detail statusz-csikjan; a verzalt a hivo adja.
  ///
  /// In hu, this message translates to:
  /// **'{date}'**
  String detailFinishedDate(DateTime date);

  /// A bója nélküli verseny meta-felirata, verzál alakban.
  ///
  /// In hu, this message translates to:
  /// **'BÓJA NÉLKÜL'**
  String get listNoMarksCaps;

  /// A lajstrom-sor bója-számlálója, verzál alakban.
  ///
  /// In hu, this message translates to:
  /// **'{count} BÓJA'**
  String listMarkCountCaps(int count);

  /// Track-stat cella verzál címkéje a detailen: maximális SOG.
  ///
  /// In hu, this message translates to:
  /// **'MAX SEB.'**
  String get detailTrackMaxSpeedCaps;

  /// Track-stat cella verzál címkéje a detailen: átlagos SOG.
  ///
  /// In hu, this message translates to:
  /// **'ÁTLAG SEB.'**
  String get detailTrackAvgSpeedCaps;

  /// Track-stat cella verzál címkéje a detailen: megtett út.
  ///
  /// In hu, this message translates to:
  /// **'TÁV'**
  String get detailTrackDistanceCaps;
}

class _ForetackUiLocalizationsDelegate
    extends LocalizationsDelegate<ForetackUiLocalizations> {
  const _ForetackUiLocalizationsDelegate();

  @override
  Future<ForetackUiLocalizations> load(Locale locale) {
    return SynchronousFuture<ForetackUiLocalizations>(
      lookupForetackUiLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_ForetackUiLocalizationsDelegate old) => false;
}

ForetackUiLocalizations lookupForetackUiLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'hu':
      return ForetackUiLocalizationsHu();
  }

  throw FlutterError(
    'ForetackUiLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
