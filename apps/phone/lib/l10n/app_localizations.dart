import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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

  /// Gomb a race-detailen: az élő verseny-képernyő megnyitása.
  ///
  /// In hu, this message translates to:
  /// **'Élő nézet'**
  String get liveOpen;

  /// Az élő képernyő üres állapota: nincs aktív verseny.
  ///
  /// In hu, this message translates to:
  /// **'Nincs aktív verseny'**
  String get liveNoActiveRace;

  /// Státuszsor chip: az adat túl régi (csatlakozott, de nem frissül).
  ///
  /// In hu, this message translates to:
  /// **'Elavult'**
  String get liveStale;

  /// Cella-címke: aktuális TWA.
  ///
  /// In hu, this message translates to:
  /// **'TWA most'**
  String get liveTwaNow;

  /// Cella-címke: a következő bójánál várható TWA.
  ///
  /// In hu, this message translates to:
  /// **'TWA köv.'**
  String get liveTwaNext;

  /// Diszkrét jel a köv-TWA hero alatt: a TWD utolsó jó értékét tartjuk (held), nincs friss derivált szélirány (ADR 0020 D7).
  ///
  /// In hu, this message translates to:
  /// **'tartott'**
  String get liveTwdHeld;

  /// Cella-címke: irány a bójához (abszolút bearing).
  ///
  /// In hu, this message translates to:
  /// **'Bearing'**
  String get liveBearing;

  /// Cella-címke: kormányzási korrekció a bójához.
  ///
  /// In hu, this message translates to:
  /// **'Korrekció'**
  String get liveCorrection;

  /// Cella-címke: távolság a bójához.
  ///
  /// In hu, this message translates to:
  /// **'Táv'**
  String get liveDistance;

  /// Cella-címke: becsült érkezés a bójához (ETA).
  ///
  /// In hu, this message translates to:
  /// **'ETA'**
  String get liveEta;

  /// Tooltip: az élő követés leállítása (AppBar ikon).
  ///
  /// In hu, this message translates to:
  /// **'Leállítás'**
  String get liveStop;

  /// A leállítás-megerősítő dialógus címe.
  ///
  /// In hu, this message translates to:
  /// **'Verseny leállítása'**
  String get liveStopTitle;

  /// A leállítás-megerősítő dialógus szövege.
  ///
  /// In hu, this message translates to:
  /// **'Biztosan leállítod az élő követést? A háttér-engine leáll.'**
  String get liveStopMessage;

  /// A leállítás-dialógus megszakító gombja.
  ///
  /// In hu, this message translates to:
  /// **'Mégse'**
  String get liveStopCancel;

  /// A leállítás-dialógus megerősítő gombja.
  ///
  /// In hu, this message translates to:
  /// **'Leállítás'**
  String get liveStopConfirm;

  /// Gomb az élő képernyőn: a jelenlegi boja kézi megjelolése megkerultnek.
  ///
  /// In hu, this message translates to:
  /// **'Bója megvan'**
  String get liveRoundMark;

  /// A kézi boja-megkerulés megerosito dialogus cime.
  ///
  /// In hu, this message translates to:
  /// **'Bója megkerülve?'**
  String get liveRoundMarkTitle;

  /// A kézi boja-megkerulés dialogus szovege a célboja nevevel.
  ///
  /// In hu, this message translates to:
  /// **'Megjelölöd a(z) {mark} át megkerültnek?'**
  String liveRoundMarkMessage(String mark);

  /// A dialogus szovege, ha a célboja neve nem ismert (pl. nincs GPS-pozicio).
  ///
  /// In hu, this message translates to:
  /// **'Megjelölöd a jelenlegi bóját megkerültnek?'**
  String get liveRoundMarkMessageGeneric;

  /// A kézi boja-megkerulés dialogus megszakito gombja.
  ///
  /// In hu, this message translates to:
  /// **'Mégse'**
  String get liveRoundMarkCancel;

  /// A kézi boja-megkerulés dialogus megerosito gombja.
  ///
  /// In hu, this message translates to:
  /// **'Megvan'**
  String get liveRoundMarkConfirm;

  /// Hibasor az élő képernyőn: a háttér-engine foreground-service indítása sikertelen.
  ///
  /// In hu, this message translates to:
  /// **'Háttér-engine hiba: {message}'**
  String liveServiceError(String message);

  /// ETA perc-egysége 60 perc felett (pl. 83 perc).
  ///
  /// In hu, this message translates to:
  /// **'perc'**
  String get etaMinutesUnit;

  /// Warning (critical): megszakadt az NMEA-adatfolyam (gateway-kapcsolat).
  ///
  /// In hu, this message translates to:
  /// **'Nincs kapcsolat a műszerekkel'**
  String get warningGatewayDisconnected;

  /// Warning (critical): nem érkezik GPS-pozíció a műszertől.
  ///
  /// In hu, this message translates to:
  /// **'Nincs GPS-jel'**
  String get warningGpsSignalLost;

  /// Warning (warning): a megjelenített GPS-idő nincs szinkronban.
  ///
  /// In hu, this message translates to:
  /// **'GPS-idő nincs szinkronban'**
  String get warningGpsTimeUnsynced;

  /// Warning (info): még nincs elég széladat a trend becsléséhez.
  ///
  /// In hu, this message translates to:
  /// **'Kevés széladat a trendhez'**
  String get warningWindShiftTrendInsufficient;

  /// Warning (warning): a heading tartósan eltér a haladási iránytól (ZG100).
  ///
  /// In hu, this message translates to:
  /// **'Iránytű gyanús – heading és irány eltér'**
  String get warningSuspectHeading;

  /// Az app neve a launcher / recents képernyőn.
  ///
  /// In hu, this message translates to:
  /// **'Foretack'**
  String get appTitle;

  /// A debug raw-NMEA viewer címsora.
  ///
  /// In hu, this message translates to:
  /// **'Nyers NMEA folyam'**
  String get viewerTitle;

  /// A viewer üres állapotának üzenete (még nincs adat).
  ///
  /// In hu, this message translates to:
  /// **'Még nem érkezett sor.'**
  String get viewerEmptyState;

  /// Connection status — TCP socket nyitás folyamatban.
  ///
  /// In hu, this message translates to:
  /// **'Csatlakozás…'**
  String get statusConnecting;

  /// Connection status — aktív kapcsolat, adat érkezik.
  ///
  /// In hu, this message translates to:
  /// **'Csatlakozva'**
  String get statusConnected;

  /// Connection status — még soha nem csatlakozott, vagy disconnect() lefutott.
  ///
  /// In hu, this message translates to:
  /// **'Nincs kapcsolat'**
  String get statusDisconnected;

  /// Connection status — szakadás üzenettel.
  ///
  /// In hu, this message translates to:
  /// **'Hiba: {message}'**
  String statusError(String message);

  /// A race-setup képernyő címsora.
  ///
  /// In hu, this message translates to:
  /// **'Új verseny'**
  String get setupTitle;

  /// A verseny nevének beviteli mezője.
  ///
  /// In hu, this message translates to:
  /// **'Verseny neve'**
  String get setupRaceNameLabel;

  /// Validációs hiba: a verseny neve üres.
  ///
  /// In hu, this message translates to:
  /// **'Adj meg egy nevet.'**
  String get setupRaceNameRequired;

  /// Egy bója-sor fejléce a sorszámmal.
  ///
  /// In hu, this message translates to:
  /// **'{number}. bója'**
  String setupMarkHeader(int number);

  /// Egy bója nevének beviteli mezője.
  ///
  /// In hu, this message translates to:
  /// **'Bója neve'**
  String get setupMarkNameLabel;

  /// Validációs hiba: a bója neve üres.
  ///
  /// In hu, this message translates to:
  /// **'Adj meg egy nevet.'**
  String get setupMarkNameRequired;

  /// Egy bója szélességének mezője, decimális fokban.
  ///
  /// In hu, this message translates to:
  /// **'Szélesség (°)'**
  String get setupLatitudeLabel;

  /// Egy bója hosszúságának mezője, decimális fokban.
  ///
  /// In hu, this message translates to:
  /// **'Hosszúság (°)'**
  String get setupLongitudeLabel;

  /// Validációs hiba: a mező nem értelmezhető számként.
  ///
  /// In hu, this message translates to:
  /// **'Érvénytelen szám.'**
  String get setupInvalidNumber;

  /// Validációs hiba: a szélesség tartományon kívül.
  ///
  /// In hu, this message translates to:
  /// **'A szélesség -90 és 90 fok között lehet.'**
  String get setupLatitudeOutOfRange;

  /// Validációs hiba: a hosszúság tartományon kívül.
  ///
  /// In hu, this message translates to:
  /// **'A hosszúság -180 és 180 fok között lehet.'**
  String get setupLongitudeOutOfRange;

  /// Validációs hiba: a koordináta egyik formátumra sem illik.
  ///
  /// In hu, this message translates to:
  /// **'Ismeretlen koordináta-formátum.'**
  String get setupCoordinateUnrecognized;

  /// Validációs hiba: a perc/másodperc a [0,60) tartományon kívül.
  ///
  /// In hu, this message translates to:
  /// **'A perc és a másodperc 0 és 60 között lehet.'**
  String get setupCoordinateComponentRange;

  /// Validációs hiba: az égtáj-betű nem illik a tengelyhez.
  ///
  /// In hu, this message translates to:
  /// **'Az égtáj-betű nem illik ehhez a mezőhöz.'**
  String get setupCoordinateCardinalMismatch;

  /// Gomb: új bója-sor hozzáadása.
  ///
  /// In hu, this message translates to:
  /// **'Bója hozzáadása'**
  String get setupAddMark;

  /// Tooltip: az adott bója-sor eltávolítása.
  ///
  /// In hu, this message translates to:
  /// **'Bója törlése'**
  String get setupRemoveMark;

  /// Tooltip: drag-handle a boja-sor atrendezesehez.
  ///
  /// In hu, this message translates to:
  /// **'Sorrend áthelyezése'**
  String get setupReorderHandle;

  /// Gomb: a verseny mentése és visszatérés a listához.
  ///
  /// In hu, this message translates to:
  /// **'Mentés'**
  String get setupSave;

  /// A verseny-szerkeszto kepernyo cimsora.
  ///
  /// In hu, this message translates to:
  /// **'Verseny szerkesztése'**
  String get editTitle;

  /// Tooltip: a verseny szerkesztese (csak notStarted).
  ///
  /// In hu, this message translates to:
  /// **'Szerkesztés'**
  String get detailEdit;

  /// Verseny-státusz: még nem indult el.
  ///
  /// In hu, this message translates to:
  /// **'Nem indult'**
  String get raceStatusNotStarted;

  /// Verseny-státusz: aktív, folyamatban van.
  ///
  /// In hu, this message translates to:
  /// **'Folyamatban'**
  String get raceStatusActive;

  /// Verseny-státusz: befejeződött.
  ///
  /// In hu, this message translates to:
  /// **'Befejezve'**
  String get raceStatusFinished;

  /// Gomb: a verseny elindítása (notStarted -> active).
  ///
  /// In hu, this message translates to:
  /// **'Indítás'**
  String get detailStart;

  /// Gomb: a verseny befejezése (active -> finished).
  ///
  /// In hu, this message translates to:
  /// **'Befejezés'**
  String get detailFinish;

  /// Tooltip: a verseny törlése (AppBar ikon).
  ///
  /// In hu, this message translates to:
  /// **'Törlés'**
  String get detailDelete;

  /// A törlés-megerősítő dialógus címe.
  ///
  /// In hu, this message translates to:
  /// **'Verseny törlése'**
  String get detailDeleteTitle;

  /// A törlés-megerősítő dialógus szövege.
  ///
  /// In hu, this message translates to:
  /// **'Biztosan törlöd ezt a versenyt?'**
  String get detailDeleteMessage;

  /// A törlés-dialógus megszakító gombja.
  ///
  /// In hu, this message translates to:
  /// **'Mégse'**
  String get detailDeleteCancel;

  /// A törlés-dialógus megerősítő gombja.
  ///
  /// In hu, this message translates to:
  /// **'Törlés'**
  String get detailDeleteConfirm;

  /// A versenylista (home) képernyő címsora.
  ///
  /// In hu, this message translates to:
  /// **'Versenyek'**
  String get listTitle;

  /// A lista üres állapotának üzenete.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs verseny. Adj hozzá egyet a + gombbal.'**
  String get listEmpty;

  /// A lista hiba-állapotának üzenete.
  ///
  /// In hu, this message translates to:
  /// **'Nem sikerült betölteni a versenyeket.'**
  String get listError;

  /// Tooltip: a FAB, ami a setup képernyőt nyitja.
  ///
  /// In hu, this message translates to:
  /// **'Új verseny'**
  String get listAddRace;

  /// A befejezett versenyek modal címsora.
  ///
  /// In hu, this message translates to:
  /// **'Befejezett versenyek'**
  String get listFinishedRacesTitle;

  /// Egy versenysor alcíme: a bóyák száma.
  ///
  /// In hu, this message translates to:
  /// **'{count} bója'**
  String listMarkCount(int count);

  /// Élő VMG csomóban, előjelesen (negatív = lemenő)
  ///
  /// In hu, this message translates to:
  /// **'VMG'**
  String get liveVmg;

  /// No description provided for @liveTargetSpeed.
  ///
  /// In hu, this message translates to:
  /// **'Cél-seb.'**
  String get liveTargetSpeed;

  /// Warning (info): a polár betöltése sikertelen (hiányzó vagy hibás asset); a cél-sebesség % nem számítható.
  ///
  /// In hu, this message translates to:
  /// **'Nincs polár-adat'**
  String get warningPolarMissing;

  /// Gomb a verseny-űrlapon: korábbi bója választása a könyvtárból.
  ///
  /// In hu, this message translates to:
  /// **'Korábbi bóják'**
  String get setupPickFromLibrary;

  /// A bója-választó (modal sheet) címe.
  ///
  /// In hu, this message translates to:
  /// **'Korábbi bóják'**
  String get setupPickFromLibraryTitle;

  /// A bója-választó üres állapota: a könyvtár üres.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs mentett bója.'**
  String get setupPickFromLibraryEmpty;

  /// A debug-only post-race elemzés szekció címe a detailen.
  ///
  /// In hu, this message translates to:
  /// **'Post-race elemzés'**
  String get detailAnalysisTitle;

  /// Üres-állapot: a befejezett versenyhez nincs snapshot-log.
  ///
  /// In hu, this message translates to:
  /// **'Nincs elemzési adat ehhez a versenyhez.'**
  String get detailAnalysisEmpty;

  /// Hiba-állapot: a post-race elemzés betöltése sikertelen.
  ///
  /// In hu, this message translates to:
  /// **'Nem sikerült betölteni az elemzést.'**
  String get detailAnalysisError;

  /// Összegző cella: a jóslat átlagos abszolút tévedése fokban.
  ///
  /// In hu, this message translates to:
  /// **'átlag |Δ|'**
  String get detailAnalysisAvgDelta;

  /// Összegző cella: a hibasávba esett megkerülések aránya.
  ///
  /// In hu, this message translates to:
  /// **'sávon belül'**
  String get detailAnalysisBandRatio;

  /// Összegző cella: az átlagos lead-time (m:ss).
  ///
  /// In hu, this message translates to:
  /// **'átlag lead'**
  String get detailAnalysisAvgLead;

  /// Megkerülés-kártya nyers szám: a jósolt TWA címkéje.
  ///
  /// In hu, this message translates to:
  /// **'jósolt'**
  String get detailAnalysisPredicted;

  /// Megkerülés-kártya nyers szám: a leg-irányra vetített (counterfactual) TWA.
  ///
  /// In hu, this message translates to:
  /// **'bója'**
  String get detailAnalysisActual;

  /// Kártya: a megbízhatósági ablak (mettől → meddig) címkéje.
  ///
  /// In hu, this message translates to:
  /// **'megbízható'**
  String get detailAnalysisReliable;

  /// A megbízhatósági ablak utótagja: az időértékek a bója előtt.
  ///
  /// In hu, this message translates to:
  /// **'a bója előtt'**
  String get detailAnalysisBeforeMark;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'hu':
      return AppLocalizationsHu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
