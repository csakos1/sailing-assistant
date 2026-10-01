import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'web_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of WebLocalizations
/// returned by `WebLocalizations.of(context)`.
///
/// Applications need to include `WebLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/web_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: WebLocalizations.localizationsDelegates,
///   supportedLocales: WebLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the WebLocalizations.supportedLocales
/// property.
abstract class WebLocalizations {
  WebLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static WebLocalizations? of(BuildContext context) {
    return Localizations.of<WebLocalizations>(context, WebLocalizations);
  }

  static const LocalizationsDelegate<WebLocalizations> delegate =
      _WebLocalizationsDelegate();

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

  /// A böngészőfül címe.
  ///
  /// In hu, this message translates to:
  /// **'Foretack archívum'**
  String get appTitle;

  /// A Versenynapló képernyő címe.
  ///
  /// In hu, this message translates to:
  /// **'Versenynapló'**
  String get logTitle;

  /// A hónap neve a Versenynapló hónap-fejlécén.
  ///
  /// In hu, this message translates to:
  /// **'{month}'**
  String logMonth(DateTime month);

  /// Verseny-darabszám az évsávon és a hónap-fejléceken (verzál).
  ///
  /// In hu, this message translates to:
  /// **'{count} VERSENY'**
  String logRaceCountCaps(int count);

  /// Az évsáv opciója, amely minden év versenyét mutatja (14w).
  ///
  /// In hu, this message translates to:
  /// **'ÖSSZES'**
  String get logAllYearsCaps;

  /// Az évsáv nagy felirata, ha az összes év van kiválasztva.
  ///
  /// In hu, this message translates to:
  /// **'{first}–{last}'**
  String logYearRange(int first, int last);

  /// A napló stat-csík első cellája: vízen töltött idő.
  ///
  /// In hu, this message translates to:
  /// **'VÍZEN TÖLTÖTT'**
  String get logStatTimeCaps;

  /// A napló stat-csík második cellája: össztáv.
  ///
  /// In hu, this message translates to:
  /// **'ÖSSZ. TÁV'**
  String get logStatDistanceCaps;

  /// A napló stat-csík harmadik cellája: sebesség-rekord.
  ///
  /// In hu, this message translates to:
  /// **'REKORD'**
  String get logStatRecordCaps;

  /// A napló hiba-állapota (13d).
  ///
  /// In hu, this message translates to:
  /// **'Nem sikerült betölteni a versenyeket. Az adat nem veszett el, csak most nem érhető el.'**
  String get logLoadError;

  /// A hiba-állapot újrapróbálás gombja.
  ///
  /// In hu, this message translates to:
  /// **'ÚJRA'**
  String get logRetryCaps;

  /// Az üres napló szövege (13b).
  ///
  /// In hu, this message translates to:
  /// **'Még nincs verseny az archívumban. Tölts fel egy telefonos adatbázist, vagy vegyél fel egy versenyt kézzel.'**
  String get logEmpty;

  /// A részletező hiba-állapota.
  ///
  /// In hu, this message translates to:
  /// **'Nem sikerült betölteni a versenyt. Az adat nem veszett el, csak most nem érhető el.'**
  String get detailLoadError;

  /// A részletező, ha a szerver RaceNotFound-ot ad.
  ///
  /// In hu, this message translates to:
  /// **'Ez a verseny már nincs az archívumban.'**
  String get detailNotFound;

  /// A kézi verseny státusz-csíkja (14m).
  ///
  /// In hu, this message translates to:
  /// **'KÉZI RÖGZÍTÉS'**
  String get detailManualCaps;

  /// A szél-csík első cellája.
  ///
  /// In hu, this message translates to:
  /// **'ÁTL. SZÉL'**
  String get detailWindAvgCaps;

  /// A szél-csík második cellája.
  ///
  /// In hu, this message translates to:
  /// **'MAX SZÉL'**
  String get detailWindMaxCaps;

  /// A szél-csík harmadik cellája.
  ///
  /// In hu, this message translates to:
  /// **'SZÉLIRÁNY'**
  String get detailWindDirectionCaps;

  /// A közelítő-sor (ADR 0048 Addendum 4 K9).
  ///
  /// In hu, this message translates to:
  /// **'~ Közelítő értékek a teljes rögzítésből. A hivatalos rajttal és befutással a versenyablakra pontosodnak.'**
  String get detailApproximate;

  /// Az eredmény-blokk szakaszcíme.
  ///
  /// In hu, this message translates to:
  /// **'EREDMÉNY'**
  String get detailResultCaps;

  /// Az üres eredmény halk sora (13l).
  ///
  /// In hu, this message translates to:
  /// **'Eredmény még nincs rögzítve.'**
  String get detailNoResult;

  /// Az osztályhelyezés cellája.
  ///
  /// In hu, this message translates to:
  /// **'OSZTÁLY'**
  String get detailClassPlaceCaps;

  /// Az abszolút helyezés cellája.
  ///
  /// In hu, this message translates to:
  /// **'ABSZOLÚT'**
  String get detailOverallPlaceCaps;

  /// Az egytestű helyezés cellája.
  ///
  /// In hu, this message translates to:
  /// **'EGYTESTŰ'**
  String get detailMonohullPlaceCaps;

  /// A YS-szám cellája.
  ///
  /// In hu, this message translates to:
  /// **'YS-SZÁM'**
  String get detailYsCaps;

  /// A hivatalos rajt cellája.
  ///
  /// In hu, this message translates to:
  /// **'HIVATALOS RAJT'**
  String get detailOfficialStartCaps;

  /// A hivatalos befutás cellája.
  ///
  /// In hu, this message translates to:
  /// **'HIVATALOS BEFUTÁS'**
  String get detailOfficialFinishCaps;

  /// A hivatalos menetidő cellája.
  ///
  /// In hu, this message translates to:
  /// **'MENETIDŐ'**
  String get detailElapsedCaps;

  /// A rajt utáni napon történt befutás jele.
  ///
  /// In hu, this message translates to:
  /// **'+1 NAP'**
  String get detailNextDayCaps;

  /// A díj címkéje.
  ///
  /// In hu, this message translates to:
  /// **'DÍJ'**
  String get detailPrizeCaps;

  /// A bóják szakaszcíme.
  ///
  /// In hu, this message translates to:
  /// **'BÓJÁK'**
  String get detailMarksCaps;

  /// Az összefoglaló szakaszcíme.
  ///
  /// In hu, this message translates to:
  /// **'ÖSSZEFOGLALÓ'**
  String get detailSummaryCaps;

  /// A térkép üres állapota.
  ///
  /// In hu, this message translates to:
  /// **'Nincs track-adat ehhez a versenyhez.'**
  String get detailTrackEmpty;

  /// A térkép-kártya tooltipje: teljes képernyős nézet.
  ///
  /// In hu, this message translates to:
  /// **'Track nagyítása'**
  String get detailTrackOpenFullscreen;

  /// A sebesség-legenda fejléce a teljes képernyős térképen.
  ///
  /// In hu, this message translates to:
  /// **'sebesség (kn)'**
  String get detailTrackLegendTitle;

  /// A legenda címkéje az ismeretlen sebességű szakaszhoz.
  ///
  /// In hu, this message translates to:
  /// **'nincs adat'**
  String get detailTrackLegendUnknown;
}

class _WebLocalizationsDelegate
    extends LocalizationsDelegate<WebLocalizations> {
  const _WebLocalizationsDelegate();

  @override
  Future<WebLocalizations> load(Locale locale) {
    return SynchronousFuture<WebLocalizations>(lookupWebLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_WebLocalizationsDelegate old) => false;
}

WebLocalizations lookupWebLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'hu':
      return WebLocalizationsHu();
  }

  throw FlutterError(
    'WebLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
