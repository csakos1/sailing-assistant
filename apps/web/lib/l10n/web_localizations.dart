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

  /// A részletező AppBarjának ceruza-gombja (ADR 0048 Addendum 4 K15).
  ///
  /// In hu, this message translates to:
  /// **'Szerkesztés'**
  String get detailEditTooltip;

  /// A telemetriás verseny eredmény-szerkesztőjének címe (G4).
  ///
  /// In hu, this message translates to:
  /// **'Eredmény szerkesztése'**
  String get editResultTitle;

  /// A szerkesztő ragadós alsó sávjának gombja.
  ///
  /// In hu, this message translates to:
  /// **'Mentés'**
  String get editSave;

  /// A telemetriás szerkesztő csak olvasható kontextus-sávja (13m).
  ///
  /// In hu, this message translates to:
  /// **'A TELEFON ADATA · NEM SZERKESZTHETŐ'**
  String get editTelemetryReadOnlyCaps;

  /// A telemetriás kontextus-sáv adatsora: a nap és a rögzítés ideje.
  ///
  /// In hu, this message translates to:
  /// **'{date} · RÖGZÍTÉS {start} – {end}'**
  String editRecordingCaps(String date, String start, String end);

  /// A szerkesztő eredmény-szakaszának címe.
  ///
  /// In hu, this message translates to:
  /// **'EREDMÉNY'**
  String get editSectionResultCaps;

  /// A szerkesztő idő-szakaszának címe.
  ///
  /// In hu, this message translates to:
  /// **'HIVATALOS IDŐ'**
  String get editSectionTimesCaps;

  /// A szerkesztő díj- és összefoglaló-szakaszának címe.
  ///
  /// In hu, this message translates to:
  /// **'DÍJ ÉS ÖSSZEFOGLALÓ'**
  String get editSectionPrizeSummaryCaps;

  /// Az osztályhelyezés sorának címkéje.
  ///
  /// In hu, this message translates to:
  /// **'Osztály'**
  String get editClassPlace;

  /// Az abszolút helyezés sorának címkéje.
  ///
  /// In hu, this message translates to:
  /// **'Abszolút'**
  String get editOverallPlace;

  /// Az egytestű helyezés sorának címkéje.
  ///
  /// In hu, this message translates to:
  /// **'Egytestű'**
  String get editMonohullPlace;

  /// A helyezés-mező felirata.
  ///
  /// In hu, this message translates to:
  /// **'HELYEZÉS'**
  String get editPlaceFieldCaps;

  /// A mezőny-mező felirata.
  ///
  /// In hu, this message translates to:
  /// **'MEZŐNY'**
  String get editFleetFieldCaps;

  /// A helyezés-szegmens számszerű cellája.
  ///
  /// In hu, this message translates to:
  /// **'SZÁM'**
  String get editPlacingNumberCaps;

  /// A helyezés-szegmens feladás-cellája.
  ///
  /// In hu, this message translates to:
  /// **'DNF'**
  String get editPlacingDnfCaps;

  /// A helyezés-szegmens kizárás-cellája.
  ///
  /// In hu, this message translates to:
  /// **'DSQ'**
  String get editPlacingDsqCaps;

  /// A YS-szám sorának címkéje.
  ///
  /// In hu, this message translates to:
  /// **'YS-szám'**
  String get editYs;

  /// A YS-mező felirata.
  ///
  /// In hu, this message translates to:
  /// **'YS'**
  String get editYsFieldCaps;

  /// A YS-mező kitöltési mintája.
  ///
  /// In hu, this message translates to:
  /// **'két tizedes, pl. 75,90'**
  String get editYsHint;

  /// A hivatalos rajt sorának címkéje.
  ///
  /// In hu, this message translates to:
  /// **'Hivatalos rajt'**
  String get editOfficialStart;

  /// A hivatalos befutás sorának címkéje.
  ///
  /// In hu, this message translates to:
  /// **'Hivatalos befutás'**
  String get editOfficialFinish;

  /// A dátummező felirata.
  ///
  /// In hu, this message translates to:
  /// **'DÁTUM'**
  String get editDateFieldCaps;

  /// A dátummező kitöltési mintája.
  ///
  /// In hu, this message translates to:
  /// **'ÉÉÉÉ.HH.NN'**
  String get editDateHint;

  /// Az időmező felirata.
  ///
  /// In hu, this message translates to:
  /// **'IDŐ'**
  String get editTimeFieldCaps;

  /// Az időmező kitöltési mintája; a másodperc nem kötelező.
  ///
  /// In hu, this message translates to:
  /// **'ÓÓ:PP(:MM)'**
  String get editTimeHint;

  /// A befutás napja: a rajt napja (K11).
  ///
  /// In hu, this message translates to:
  /// **'AZNAP'**
  String get editSameDayCaps;

  /// A befutás napja: a rajt utáni nap (K11).
  ///
  /// In hu, this message translates to:
  /// **'+1 NAP'**
  String get editNextDayCaps;

  /// A befutás napja: a rajt utáni második nap (K11).
  ///
  /// In hu, this message translates to:
  /// **'+2 NAP'**
  String get editSecondDayCaps;

  /// A számolt menetidő sorának címkéje.
  ///
  /// In hu, this message translates to:
  /// **'Menetidő'**
  String get editElapsed;

  /// A számolt sorok címke-alatti jele.
  ///
  /// In hu, this message translates to:
  /// **'SZÁMOLT'**
  String get editComputedCaps;

  /// A hiányzó menetidő magyarázata.
  ///
  /// In hu, this message translates to:
  /// **'A HIVATALOS RAJTBÓL ÉS BEFUTÁSBÓL'**
  String get editElapsedSourceCaps;

  /// A díj mezőjének címe.
  ///
  /// In hu, this message translates to:
  /// **'Díj'**
  String get editPrize;

  /// A díj-mező felirata.
  ///
  /// In hu, this message translates to:
  /// **'RÖVID SZÖVEG'**
  String get editPrizeFieldCaps;

  /// A díj-mező kitöltési mintája.
  ///
  /// In hu, this message translates to:
  /// **'pl. érem, kupa, Hungária pezsgő'**
  String get editPrizeHint;

  /// Az összefoglaló mezőjének címe.
  ///
  /// In hu, this message translates to:
  /// **'Összefoglaló'**
  String get editSummary;

  /// Az összefoglaló-mező felirata.
  ///
  /// In hu, this message translates to:
  /// **'SIMA SZÖVEG'**
  String get editSummaryFieldCaps;

  /// Az összefoglaló-mező kitöltési mintája.
  ///
  /// In hu, this message translates to:
  /// **'Hogyan ment a verseny? Szél, taktika, tanulságok…'**
  String get editSummaryHint;

  /// Hibaüzenet: a helyezés vagy a mezőny nem egész szám.
  ///
  /// In hu, this message translates to:
  /// **'Csak pozitív egész szám írható ide.'**
  String get editProblemWholeNumber;

  /// Hibaüzenet: a mennyiség nem szám.
  ///
  /// In hu, this message translates to:
  /// **'Szám kell, pl. 10,2.'**
  String get editProblemDecimal;

  /// Hibaüzenet: rossz YS-formátum (14p).
  ///
  /// In hu, this message translates to:
  /// **'Két tizedes kell, pl. 75,90.'**
  String get editProblemYs;

  /// Hibaüzenet: olvashatatlan vagy nem létező nap.
  ///
  /// In hu, this message translates to:
  /// **'Hibás dátum, pl. 2026.06.13.'**
  String get editProblemDate;

  /// Hibaüzenet: olvashatatlan idő.
  ///
  /// In hu, this message translates to:
  /// **'Hibás idő, pl. 10:00 vagy 10:00:30.'**
  String get editProblemTime;

  /// Hibaüzenet: nem pozitív helyezés (13n).
  ///
  /// In hu, this message translates to:
  /// **'A helyezés legalább 1.'**
  String get editProblemPlaceAtLeastOne;

  /// Hibaüzenet: nem pozitív mezőny.
  ///
  /// In hu, this message translates to:
  /// **'A mezőny legalább 1.'**
  String get editProblemFleetAtLeastOne;

  /// Hibaüzenet: nulla YS-szám.
  ///
  /// In hu, this message translates to:
  /// **'A YS-szám nem lehet nulla.'**
  String get editProblemYsAtLeastOne;

  /// Hibaüzenet: a helyezés nagyobb a saját mezőnyénél (14p).
  ///
  /// In hu, this message translates to:
  /// **'A helyezés nem lehet nagyobb a mezőnynél ({fleetSize}).'**
  String editProblemPlaceExceedsFleet(String fleetSize);

  /// Hibaüzenet: a befutás nem a rajt után van (14p).
  ///
  /// In hu, this message translates to:
  /// **'A befutás nem későbbi a rajtnál. Másnap értetek be? Válaszd a +1 NAP-ot.'**
  String get editProblemFinishNotAfterStart;

  /// Hibaüzenet: negatív mennyiség.
  ///
  /// In hu, this message translates to:
  /// **'Nem lehet negatív.'**
  String get editProblemNegative;

  /// Hibaüzenet: üres kötelező mező.
  ///
  /// In hu, this message translates to:
  /// **'Kötelező mező.'**
  String get editProblemRequired;

  /// Hibaüzenet: nem pozitív érték egyéb mezőben.
  ///
  /// In hu, this message translates to:
  /// **'Az érték legalább 1.'**
  String get editProblemAtLeastOne;

  /// A mentés hibája a Mentés gomb fölött (K16).
  ///
  /// In hu, this message translates to:
  /// **'A mentés nem sikerült. A változtatások megmaradtak, próbáld újra.'**
  String get editSaveFailed;

  /// A mentés hibája, ha a szerver RaceNotFound-ot ad.
  ///
  /// In hu, this message translates to:
  /// **'Ez a verseny már nincs az archívumban.'**
  String get editRaceGone;

  /// A mentetlen változtatás dialógusának címe (13o).
  ///
  /// In hu, this message translates to:
  /// **'Elveted a változtatásokat?'**
  String get editDiscardTitle;

  /// A mentetlen változtatás dialógusának szövege (13o).
  ///
  /// In hu, this message translates to:
  /// **'A módosításokat nem mentetted. Ha most kilépsz, elvesznek.'**
  String get editDiscardMessage;

  /// A 13o biztonságos akciója.
  ///
  /// In hu, this message translates to:
  /// **'Folytatom'**
  String get editDiscardKeep;

  /// A 13o destruktív akciója.
  ///
  /// In hu, this message translates to:
  /// **'Elvetés'**
  String get editDiscardConfirm;

  /// Snackbar az eredmény mentése után (ADR 0047 E6).
  ///
  /// In hu, this message translates to:
  /// **'Eredmény mentve'**
  String get snackResultSaved;

  /// A napló AppBarjának gombja: üres kézi-verseny szerkesztő (G1).
  ///
  /// In hu, this message translates to:
  /// **'Új verseny'**
  String get logNewRace;

  /// Az új kézi verseny szerkesztőjének címe (G4).
  ///
  /// In hu, this message translates to:
  /// **'Új verseny'**
  String get newRaceTitle;

  /// A kézi verseny szerkesztőjének címe (G4).
  ///
  /// In hu, this message translates to:
  /// **'Verseny szerkesztése'**
  String get editManualTitle;

  /// A kézi szerkesztő kuka-gombja (G5).
  ///
  /// In hu, this message translates to:
  /// **'Verseny törlése'**
  String get editDeleteTooltip;

  /// A kézi szerkesztő státusz-sávja (14r).
  ///
  /// In hu, this message translates to:
  /// **'KÉZI VERSENY'**
  String get editManualCaps;

  /// A kézi szerkesztő státusz-sávjának jobb oldala (14r).
  ///
  /// In hu, this message translates to:
  /// **'TELEMETRIA NÉLKÜL · NINCS TÉRKÉP ÉS BÓJA'**
  String get editManualNoTelemetryCaps;

  /// A kézi szerkesztő alapadat-szakaszának címe.
  ///
  /// In hu, this message translates to:
  /// **'VERSENY'**
  String get editSectionRaceCaps;

  /// A verseny nevének sor-címkéje.
  ///
  /// In hu, this message translates to:
  /// **'Név'**
  String get editName;

  /// A kötelező mező címke-alatti jele.
  ///
  /// In hu, this message translates to:
  /// **'KÖTELEZŐ'**
  String get editRequiredCaps;

  /// A név-mező felirata.
  ///
  /// In hu, this message translates to:
  /// **'NÉV'**
  String get editNameFieldCaps;

  /// A név-mező kitöltési mintája.
  ///
  /// In hu, this message translates to:
  /// **'pl. 57. Kékszalag (nyílt)'**
  String get editNameHint;

  /// A verseny napjának sor-címkéje.
  ///
  /// In hu, this message translates to:
  /// **'Dátum'**
  String get editDate;

  /// A kézi szerkesztő stat-szakaszának címe.
  ///
  /// In hu, this message translates to:
  /// **'TÁV ÉS SZÉL'**
  String get editSectionDistanceWindCaps;

  /// A táv és a max. sebesség sorának címkéje.
  ///
  /// In hu, this message translates to:
  /// **'Táv és sebesség'**
  String get editDistanceSpeed;

  /// A táv-mező felirata.
  ///
  /// In hu, this message translates to:
  /// **'TÁV · KM'**
  String get editDistanceFieldCaps;

  /// A max. sebesség és a max. szél mezőjének felirata.
  ///
  /// In hu, this message translates to:
  /// **'MAX · KN'**
  String get editMaxKnotsFieldCaps;

  /// A számolt átlagsebesség sorának címkéje.
  ///
  /// In hu, this message translates to:
  /// **'Átlagsebesség'**
  String get editAvgSpeed;

  /// A hiányzó átlagsebesség magyarázata.
  ///
  /// In hu, this message translates to:
  /// **'TÁVBÓL ÉS MENETIDŐBŐL SZÁMOLVA'**
  String get editAvgSpeedSourceCaps;

  /// A számolt átlagsebesség értéke csomóban.
  ///
  /// In hu, this message translates to:
  /// **'{value} kn'**
  String editKnotsValue(String value);

  /// Az átlagos és a max. szél sorának címkéje.
  ///
  /// In hu, this message translates to:
  /// **'Szél'**
  String get editWind;

  /// Az átlagos szél mezőjének felirata.
  ///
  /// In hu, this message translates to:
  /// **'ÁTLAG · KN'**
  String get editAvgKnotsFieldCaps;

  /// A szélirány sorának címkéje.
  ///
  /// In hu, this message translates to:
  /// **'Szélirány'**
  String get editWindDirection;

  /// A szélirány-lista üres eleme (K12).
  ///
  /// In hu, this message translates to:
  /// **'nincs megadva'**
  String get editWindDirectionNone;

  /// A szélirány-lista felirata.
  ///
  /// In hu, this message translates to:
  /// **'HONNAN FÚJ'**
  String get editWindFromCaps;

  /// A törlés megerősítő dialógusának címe (14t).
  ///
  /// In hu, this message translates to:
  /// **'Törlöd a versenyt?'**
  String get editDeleteTitle;

  /// A törlés megerősítő dialógusának szövege (14t).
  ///
  /// In hu, this message translates to:
  /// **'A kézi verseny minden adata törlődik az archívumból. A törlés végleges, nem vonható vissza.'**
  String get editDeleteMessage;

  /// A törlés-dialógus biztonságos akciója.
  ///
  /// In hu, this message translates to:
  /// **'Mégse'**
  String get editDeleteCancel;

  /// A törlés-dialógus destruktív akciója.
  ///
  /// In hu, this message translates to:
  /// **'Törlés'**
  String get editDeleteConfirm;

  /// A törlés-dialógus adatcellájának első sora.
  ///
  /// In hu, this message translates to:
  /// **'Verseny'**
  String get editDeleteRowRace;

  /// A törlés-dialógus adatcellájának második sora.
  ///
  /// In hu, this message translates to:
  /// **'Dátum'**
  String get editDeleteRowDate;

  /// A törlés hibája a Mentés gomb fölött.
  ///
  /// In hu, this message translates to:
  /// **'A törlés nem sikerült. Próbáld újra.'**
  String get editDeleteFailed;

  /// Snackbar a kézi verseny mentése után (K15).
  ///
  /// In hu, this message translates to:
  /// **'Verseny mentve'**
  String get snackRaceSaved;

  /// Snackbar az új verseny létrehozása után (G5).
  ///
  /// In hu, this message translates to:
  /// **'Verseny létrehozva'**
  String get snackRaceCreated;

  /// Snackbar a törlés után (G5).
  ///
  /// In hu, this message translates to:
  /// **'Verseny törölve'**
  String get snackRaceDeleted;

  /// A napló AppBarjának gombja: a feltöltés-dialógust nyitja (G1, K23).
  ///
  /// In hu, this message translates to:
  /// **'Feltöltés'**
  String get logUpload;

  /// A feltöltés-dialógus címe (13f).
  ///
  /// In hu, this message translates to:
  /// **'Adatbázis feltöltése'**
  String get importTitle;

  /// A feltöltés-dialógus magyarázata (13f).
  ///
  /// In hu, this message translates to:
  /// **'A telefon Foretack-adatbázisa. A befejezett versenyek bekerülnek a naplóba, a már meglévők frissülnek.'**
  String get importMessage;

  /// A fő fájl cellájának verzál felirata (13f).
  ///
  /// In hu, this message translates to:
  /// **'ADATBÁZIS · KÖTELEZŐ'**
  String get importDatabaseLabelCaps;

  /// A -wal fájl cellájának verzál felirata (13f).
  ///
  /// In hu, this message translates to:
  /// **'WAL-FÁJL · OPCIONÁLIS'**
  String get importWalLabelCaps;

  /// Az üres fájl-cella szövege (13g; a ráhúzás később jön, K19).
  ///
  /// In hu, this message translates to:
  /// **'Nincs kiválasztva'**
  String get importNoFile;

  /// Az üres fájl-cella akciója (13g).
  ///
  /// In hu, this message translates to:
  /// **'TALLÓZÁS'**
  String get importBrowseCaps;

  /// A kiválasztott fájl cellájának akciója (13f).
  ///
  /// In hu, this message translates to:
  /// **'CSERE'**
  String get importReplaceCaps;

  /// Magyarázat a -wal cella alatt (13f).
  ///
  /// In hu, this message translates to:
  /// **'A -wal fájl a legutóbbi verseny adatainak egy részét hordozhatja, ezért érdemes azt is feltölteni.'**
  String get importWalHint;

  /// A feltöltés-dialógus bezáró akciója; feltöltés közben megszakít (K20).
  ///
  /// In hu, this message translates to:
  /// **'Mégse'**
  String get importCancel;

  /// A feltöltést indító akció (13f).
  ///
  /// In hu, this message translates to:
  /// **'Feltöltés'**
  String get importStart;

  /// Az akció felirata feltöltés közben, a forgó mellett (13h).
  ///
  /// In hu, this message translates to:
  /// **'Feltöltés…'**
  String get importUploading;

  /// A feltöltés haladása a címsorban (13h).
  ///
  /// In hu, this message translates to:
  /// **'{percent} %'**
  String importPercent(int percent);

  /// A címsor felirata, amikor minden bájt kiment, és a szerver dolgozik (K20).
  ///
  /// In hu, this message translates to:
  /// **'FELDOLGOZÁS'**
  String get importProcessingCaps;

  /// A sikeres import címe (13i).
  ///
  /// In hu, this message translates to:
  /// **'Feltöltés kész'**
  String get importDoneTitle;

  /// A sikeres import magyarázata (13i).
  ///
  /// In hu, this message translates to:
  /// **'A napló a bezáráskor frissül.'**
  String get importDoneMessage;

  /// Halk mondat a sikeres import alatt, ha a szerver figyelmen kívül hagyta a -wal fájlt (K20).
  ///
  /// In hu, this message translates to:
  /// **'A WAL-fájl érvénytelen volt, ezért csak a fő fájl adatai kerültek be.'**
  String get importWalIgnored;

  /// A sikeres import szövege, ha egyik csoportban sincs verseny (K21).
  ///
  /// In hu, this message translates to:
  /// **'A fájlban nem volt verseny.'**
  String get importNothingFound;

  /// Az eredmény-lista csoportja: újonnan felvett versenyek (13i; a fejléc verzálosít).
  ///
  /// In hu, this message translates to:
  /// **'Új'**
  String get importGroupAdded;

  /// Az eredmény-lista csoportja: frissült versenyek (13i).
  ///
  /// In hu, this message translates to:
  /// **'Frissült'**
  String get importGroupUpdated;

  /// Az eredmény-lista csoportja: kihagyott, nem befejezett versenyek (13i).
  ///
  /// In hu, this message translates to:
  /// **'Kimaradt · nem befejezett'**
  String get importGroupSkipped;

  /// A verseny rövid dátuma az eredmény-lista sorának jobb szélén (13i; a widget verzálosít).
  ///
  /// In hu, this message translates to:
  /// **'{date}'**
  String importRaceDate(DateTime date);

  /// Az eredmény és a séma-hiba egyetlen akciója (13i, 13j).
  ///
  /// In hu, this message translates to:
  /// **'Bezárás'**
  String get importClose;

  /// A séma-hiba címe (13j).
  ///
  /// In hu, this message translates to:
  /// **'Az app újabb adatbázis-verziót használ'**
  String get importSchemaTitle;

  /// A séma-hiba magyarázata (13j).
  ///
  /// In hu, this message translates to:
  /// **'Frissítsd a szervert, és töltsd fel újra a fájlt. A napló nem változott.'**
  String get importSchemaMessage;

  /// A séma-hiba adatcellájának második címkéje (13j).
  ///
  /// In hu, this message translates to:
  /// **'Szerver'**
  String get importSchemaServer;

  /// Egy sémaverzió az adatcellában (13j).
  ///
  /// In hu, this message translates to:
  /// **'SÉMA v{version}'**
  String importSchemaVersionCaps(int version);

  /// Hálózati hiba a feltöltés közben (K20).
  ///
  /// In hu, this message translates to:
  /// **'A feltöltés megszakadt. Ellenőrizd a kapcsolatot, és próbáld újra.'**
  String get importFailedNetwork;

  /// A szerver elutasította: a fő fájl nem SQLite (K20).
  ///
  /// In hu, this message translates to:
  /// **'A kiválasztott fájl nem SQLite-adatbázis.'**
  String get importFailedNotSqlite;

  /// A szerver elutasította: idegen adatbázis (K20).
  ///
  /// In hu, this message translates to:
  /// **'A kiválasztott fájl nem a Foretack adatbázisa.'**
  String get importFailedNotForetack;

  /// A szerver elutasította: hiányzik a fő fájl (K20).
  ///
  /// In hu, this message translates to:
  /// **'A fő adatbázis-fájl nem érkezett meg. Válaszd ki újra, és próbáld újra.'**
  String get importFailedMainFileMissing;

  /// A szerver elutasította: túl nagy törzs (K20).
  ///
  /// In hu, this message translates to:
  /// **'A fájl nagyobb a szerver korlátjánál ({limit}).'**
  String importFailedTooLarge(String limit);

  /// Bármely más szerverhiba a feltöltés után (K20).
  ///
  /// In hu, this message translates to:
  /// **'A szerver nem tudta feldolgozni a fájlt. Próbáld újra később.'**
  String get importFailedServer;

  /// A napló nézet-váltójának első cellája (G1, K32).
  ///
  /// In hu, this message translates to:
  /// **'Lista'**
  String get logViewList;

  /// A napló nézet-váltójának második cellája (G1, K32).
  ///
  /// In hu, this message translates to:
  /// **'Táblázat'**
  String get logViewTable;

  /// A nézet-váltó csoportjának szemantikai címkéje (K32).
  ///
  /// In hu, this message translates to:
  /// **'Napló nézete'**
  String get logViewToggleLabel;

  /// A táblázat csoportsora: dátum és név (G2).
  ///
  /// In hu, this message translates to:
  /// **'VERSENY'**
  String get tableGroupRaceCaps;

  /// A táblázat csoportsora: helyezések és YS (G2).
  ///
  /// In hu, this message translates to:
  /// **'EREDMÉNY · HELYEZÉS/MEZŐNY'**
  String get tableGroupResultCaps;

  /// A táblázat csoportsora: rajt, befutás, menetidő, táv (G2).
  ///
  /// In hu, this message translates to:
  /// **'IDŐ ÉS TÁV'**
  String get tableGroupTimeCaps;

  /// A táblázat csoportsora: sebesség, szél, irány (G2).
  ///
  /// In hu, this message translates to:
  /// **'SEBESSÉG ÉS SZÉL'**
  String get tableGroupSpeedCaps;

  /// A táblázat csoportsora: a díj (G2).
  ///
  /// In hu, this message translates to:
  /// **'DÍJ'**
  String get tableGroupPrizeCaps;

  /// Oszlopfejléc (G2).
  ///
  /// In hu, this message translates to:
  /// **'DÁTUM'**
  String get tableColumnDateCaps;

  /// Oszlopfejléc (G2).
  ///
  /// In hu, this message translates to:
  /// **'VERSENY'**
  String get tableColumnNameCaps;

  /// Oszlopfejléc: osztályhelyezés (G2).
  ///
  /// In hu, this message translates to:
  /// **'OSZT.'**
  String get tableColumnClassCaps;

  /// Oszlopfejléc: abszolút helyezés (G2).
  ///
  /// In hu, this message translates to:
  /// **'ABSZ.'**
  String get tableColumnOverallCaps;

  /// Oszlopfejléc: egytestű helyezés (G2).
  ///
  /// In hu, this message translates to:
  /// **'EGYT.'**
  String get tableColumnMonohullCaps;

  /// Oszlopfejléc: YS-szám (G2).
  ///
  /// In hu, this message translates to:
  /// **'YS'**
  String get tableColumnYsCaps;

  /// Oszlopfejléc (G2).
  ///
  /// In hu, this message translates to:
  /// **'RAJT'**
  String get tableColumnStartCaps;

  /// Oszlopfejléc (G2).
  ///
  /// In hu, this message translates to:
  /// **'BEFUTÁS'**
  String get tableColumnFinishCaps;

  /// Oszlopfejléc (G2).
  ///
  /// In hu, this message translates to:
  /// **'MENETIDŐ'**
  String get tableColumnElapsedCaps;

  /// Oszlopfejléc (G2).
  ///
  /// In hu, this message translates to:
  /// **'TÁV'**
  String get tableColumnDistanceCaps;

  /// Oszlopfejléc: átlagsebesség (G2).
  ///
  /// In hu, this message translates to:
  /// **'ÁTLAG'**
  String get tableColumnAvgSpeedCaps;

  /// Oszlopfejléc: legnagyobb sebesség (G2).
  ///
  /// In hu, this message translates to:
  /// **'MAX'**
  String get tableColumnMaxSpeedCaps;

  /// Oszlopfejléc (G2).
  ///
  /// In hu, this message translates to:
  /// **'ÁTL. SZÉL'**
  String get tableColumnAvgWindCaps;

  /// Oszlopfejléc (G2).
  ///
  /// In hu, this message translates to:
  /// **'MAX SZÉL'**
  String get tableColumnMaxWindCaps;

  /// Oszlopfejléc: uralkodó szélirány (G2).
  ///
  /// In hu, this message translates to:
  /// **'IRÁNY'**
  String get tableColumnDirectionCaps;

  /// Oszlopfejléc (G2).
  ///
  /// In hu, this message translates to:
  /// **'DÍJ'**
  String get tableColumnPrizeCaps;

  /// Címke a kézi verseny neve után a táblázatban (G6).
  ///
  /// In hu, this message translates to:
  /// **'KÉZI'**
  String get tableManualCaps;

  /// Jel a másnapi befutás mellett (G2).
  ///
  /// In hu, this message translates to:
  /// **'+1'**
  String get tableNextDay;

  /// A rendezett oszlop fejlécének szemantikai címkéje (K29).
  ///
  /// In hu, this message translates to:
  /// **'{column}, növekvő sorrend'**
  String tableSortedAscending(String column);

  /// A rendezett oszlop fejlécének szemantikai címkéje (K29).
  ///
  /// In hu, this message translates to:
  /// **'{column}, csökkenő sorrend'**
  String tableSortedDescending(String column);

  /// Mértékegység a Táv fejlécében (L5).
  ///
  /// In hu, this message translates to:
  /// **'km'**
  String get tableUnitKilometers;

  /// Mértékegység a sebesség és a szél fejlécében (L5).
  ///
  /// In hu, this message translates to:
  /// **'kn'**
  String get tableUnitKnots;

  /// A rajt és a befutás fejlécének második sora (L5).
  ///
  /// In hu, this message translates to:
  /// **'ó:p'**
  String get tableUnitClock;

  /// A menetidő fejlécének második sora (L5).
  ///
  /// In hu, this message translates to:
  /// **'ó:p:mp'**
  String get tableUnitElapsed;

  /// Halk sor a kézi szerkesztő stat-szakaszában, ha a statok a régi trackből számoltak (ADR 0050 Addendum 2 F3).
  ///
  /// In hu, this message translates to:
  /// **'A táv, a sebesség és a szél a régi trackből számolódik, a hivatalos rajt és befutás között.'**
  String get editStatsFromTrackNote;

  /// Az átlagsebesség magyarázata, ha a trackből számolt, de nincs értéke.
  ///
  /// In hu, this message translates to:
  /// **'A TRACKBŐL SZÁMOLVA'**
  String get editAvgSpeedTrackSourceCaps;

  /// A napló AppBar ikon-gombjának tooltipje, amely a Statisztika-képernyőt nyitja (ADR 0049 Addendum 1 P1).
  ///
  /// In hu, this message translates to:
  /// **'Statisztika'**
  String get logStatistics;

  /// A napló AppBar ikon-gombjának tooltipje, amely a teljes exportot (tar.gz) tölti le (ADR 0050 Addendum 3 G1).
  ///
  /// In hu, this message translates to:
  /// **'Export'**
  String get logExport;

  /// A Statisztika-képernyő címe (ADR 0049 D2).
  ///
  /// In hu, this message translates to:
  /// **'Statisztika'**
  String get statsTitle;

  /// A Statisztika MENNYISÉG csíkjának első cellája: a versenyek száma.
  ///
  /// In hu, this message translates to:
  /// **'VERSENY'**
  String get statsStatRacesCaps;

  /// Az éremtábla oszlopa: dobogós versenyek száma és aránya (ADR 0049 Addendum 2 R3).
  ///
  /// In hu, this message translates to:
  /// **'DOBOGÓS'**
  String get statsColumnPodiumCaps;

  /// A szélsávok szakaszcíme (Addendum 1 P3, Addendum 2 R2).
  ///
  /// In hu, this message translates to:
  /// **'ÁTLAGSZÉL SZERINT'**
  String get statsWindBandsCaps;

  /// A legalsó szélsáv címkéje.
  ///
  /// In hu, this message translates to:
  /// **'< {high} kn'**
  String statsWindBandBelow(int high);

  /// Egy közbülső szélsáv címkéje.
  ///
  /// In hu, this message translates to:
  /// **'{low}–{high} kn'**
  String statsWindBandRange(int low, int high);

  /// A legfelső szélsáv címkéje.
  ///
  /// In hu, this message translates to:
  /// **'≥ {low} kn'**
  String statsWindBandAbove(int low);

  /// Az éremtábla első oszlopa (R3).
  ///
  /// In hu, this message translates to:
  /// **'ÉV'**
  String get statsColumnYearCaps;

  /// Az egy-év nézet első szakaszcíme (R2).
  ///
  /// In hu, this message translates to:
  /// **'AZ ÉVAD'**
  String get statsSeasonCaps;

  /// Az évad nagy száma: hány versenyen volt osztály- vagy abszolút dobogó (R5).
  ///
  /// In hu, this message translates to:
  /// **'DOBOGÓS VERSENY'**
  String get statsPodiumRacesCaps;

  /// Az évad nagy száma: dobogós versenyek a megjelenített versenyekhez (R5).
  ///
  /// In hu, this message translates to:
  /// **'DOBOGÓS ARÁNY'**
  String get statsPodiumRateCaps;

  /// A dobogós helyezések száma; az évad sorában és a kategóriák alján (R5).
  ///
  /// In hu, this message translates to:
  /// **'DOBOGÓS HELYEZÉS'**
  String get statsPodiumPlacingsCaps;

  /// Az osztályhelyezések szakaszcíme és éremtábla-oszlopa (R2, R3).
  ///
  /// In hu, this message translates to:
  /// **'OSZTÁLYBAN'**
  String get statsClassCaps;

  /// Az összevont abszolút helyezések szakaszcíme és éremtábla-oszlopa (R1).
  ///
  /// In hu, this message translates to:
  /// **'ABSZOLÚT'**
  String get statsOverallCaps;

  /// Az első helyek sora egy kategóriában.
  ///
  /// In hu, this message translates to:
  /// **'I. HELY'**
  String get statsFirstPlaceCaps;

  /// A második helyek sora egy kategóriában.
  ///
  /// In hu, this message translates to:
  /// **'II. HELY'**
  String get statsSecondPlaceCaps;

  /// A harmadik helyek sora egy kategóriában.
  ///
  /// In hu, this message translates to:
  /// **'III. HELY'**
  String get statsThirdPlaceCaps;

  /// A százalék utáni szöveg egy helyezés-sorban.
  ///
  /// In hu, this message translates to:
  /// **'a {total} indulásból'**
  String statsOfStarts(int total);

  /// A dobogón kívüli helyezések sorának eleje (R4).
  ///
  /// In hu, this message translates to:
  /// **'Dobogón kívül:'**
  String get statsOffPodium;

  /// A pálya-mutatók szakaszcíme (R2).
  ///
  /// In hu, this message translates to:
  /// **'A PÁLYÁN'**
  String get statsTrackCaps;

  /// Pálya-mutató: a leghosszabb táv versenye.
  ///
  /// In hu, this message translates to:
  /// **'LEGHOSSZABB TÁV'**
  String get statsLongestRaceCaps;

  /// Pálya-mutató: össztáv ÷ összidő.
  ///
  /// In hu, this message translates to:
  /// **'ÁTLAGSEBESSÉG'**
  String get statsAverageSpeedCaps;

  /// Pálya-mutató: a legnagyobb átlagsebességű verseny.
  ///
  /// In hu, this message translates to:
  /// **'LEGGYORSABB VERSENY'**
  String get statsFastestAverageCaps;

  /// Pálya-mutató: a legnagyobb max. sebesség versenye.
  ///
  /// In hu, this message translates to:
  /// **'CSÚCSSEBESSÉG'**
  String get statsTopSpeedCaps;

  /// Pálya-mutató: a legnagyobb max. szél versenye.
  ///
  /// In hu, this message translates to:
  /// **'LEGERŐSEBB SZÉL'**
  String get statsStrongestWindCaps;

  /// Pálya-mutató: a leggyakoribb égtáj.
  ///
  /// In hu, this message translates to:
  /// **'URALKODÓ SZÉLIRÁNY'**
  String get statsPrevailingWindCaps;

  /// Az összes év nézet első szakaszcíme (R3).
  ///
  /// In hu, this message translates to:
  /// **'ÉREMTÁBLA ÉVENKÉNT'**
  String get statsMedalTableCaps;

  /// Az éremtábla oszlopa: versenyek száma.
  ///
  /// In hu, this message translates to:
  /// **'INDULÁS'**
  String get statsColumnStartsCaps;

  /// Az éremtábla oszlopa: az év dobogós helyezései vitorlákkal.
  ///
  /// In hu, this message translates to:
  /// **'AZ ÉV TERMÉSE'**
  String get statsColumnHarvestCaps;

  /// Az éremtábla összesítő sorának címkéje.
  ///
  /// In hu, this message translates to:
  /// **'Össz.'**
  String get statsTotalRow;

  /// Az éremtábla összesítő sorában a dobogós helyezések száma után.
  ///
  /// In hu, this message translates to:
  /// **'dobogós helyezés'**
  String get statsHarvestTotal;

  /// Az egy év nézet polár-szakaszának címe (W1).
  ///
  /// In hu, this message translates to:
  /// **'POLÁR-TELJESÍTMÉNY'**
  String get polarSeasonSectionCaps;

  /// A polár-szakaszcím jobb oldali halk felirata egy év nézetben.
  ///
  /// In hu, this message translates to:
  /// **'{count} verseny · időrendben'**
  String polarSeasonTrailing(int count);

  /// Az összes év nézet polár-szakaszának címe (W1).
  ///
  /// In hu, this message translates to:
  /// **'POLÁR ÉVENKÉNT'**
  String get polarYearsSectionCaps;

  /// A polár-szakaszcím jobb oldali halk felirata az összes év nézetben.
  ///
  /// In hu, this message translates to:
  /// **'időre súlyozva · {count} verseny'**
  String polarYearsTrailing(int count);

  /// A polár-táblázat fejlécének csoportcíme a százalék-oszlopok fölött.
  ///
  /// In hu, this message translates to:
  /// **'POLÁR %'**
  String get polarGroupPercentCaps;

  /// A polár-táblázat fejlécének csoportcíme a két időarány fölött.
  ///
  /// In hu, this message translates to:
  /// **'AZ IDŐ %'**
  String get polarGroupTimeCaps;

  /// A polár-táblázat oszlopa: év.
  ///
  /// In hu, this message translates to:
  /// **'ÉV'**
  String get polarColumnYearCaps;

  /// A polár-táblázat oszlopa: szezonbeli rang.
  ///
  /// In hu, this message translates to:
  /// **'RANG'**
  String get polarColumnRankCaps;

  /// A polár-táblázat oszlopa: a verseny napja.
  ///
  /// In hu, this message translates to:
  /// **'DÁTUM'**
  String get polarColumnDateCaps;

  /// A polár-táblázat oszlopa: a verseny neve vagy a versenyek száma.
  ///
  /// In hu, this message translates to:
  /// **'VERSENY'**
  String get polarColumnRaceCaps;

  /// A polár-táblázat oszlopa: átlagos TWS.
  ///
  /// In hu, this message translates to:
  /// **'SZÉL'**
  String get polarColumnWindCaps;

  /// Polár-mutató: a százalékok átlaga.
  ///
  /// In hu, this message translates to:
  /// **'ÁTLAG'**
  String get polarColumnAverageCaps;

  /// Polár-mutató: a százalékok mediánja.
  ///
  /// In hu, this message translates to:
  /// **'MEDIÁN'**
  String get polarColumnMedianCaps;

  /// Polár-mutató: a százalékok 90. percentilise.
  ///
  /// In hu, this message translates to:
  /// **'P90'**
  String get polarColumnP90Caps;

  /// Polár-mutató: a százalékok 99. percentilise.
  ///
  /// In hu, this message translates to:
  /// **'P99'**
  String get polarColumnP99Caps;

  /// A polár-táblázat oszlopa: legjobb 5 mp, első sor.
  ///
  /// In hu, this message translates to:
  /// **'LEGJOBB'**
  String get polarColumnBestCaps;

  /// A polár-táblázat oszlopa: legjobb 5 mp, második sor.
  ///
  /// In hu, this message translates to:
  /// **'5 MP'**
  String get polarColumnBestUnitCaps;

  /// A polár-táblázat oszlopa: a 90% fölötti idő, első sor.
  ///
  /// In hu, this message translates to:
  /// **'90%'**
  String get polarColumnAbove90Caps;

  /// A polár-táblázat oszlopa: a 100% fölötti idő, első sor.
  ///
  /// In hu, this message translates to:
  /// **'100%'**
  String get polarColumnAbove100Caps;

  /// A két időarány-oszlop második sora.
  ///
  /// In hu, this message translates to:
  /// **'FELETT'**
  String get polarColumnAboveUnitCaps;

  /// A RANG fejléc és a SZEZONBELI RANG tooltipje.
  ///
  /// In hu, this message translates to:
  /// **'Szélvödrökre standardizált átlag'**
  String get polarRankTooltip;

  /// A ≈ jel tooltipje.
  ///
  /// In hu, this message translates to:
  /// **'Közelítő: nincs hivatalos rajt és befutás, a teljes rögzítésből'**
  String get polarApproximateTooltip;

  /// Az évsorban a versenyszám utáni halk toldalék.
  ///
  /// In hu, this message translates to:
  /// **'vers.'**
  String get polarYearRacesSuffix;

  /// Az első összesítő sor felirata.
  ///
  /// In hu, this message translates to:
  /// **'A futamok átlaga'**
  String get polarRaceAverage;

  /// A második összesítő sor felirata.
  ///
  /// In hu, this message translates to:
  /// **'Időre súlyozva'**
  String get polarTimeWeighted;

  /// A mért idő összege az összesítő sorok alatt.
  ///
  /// In hu, this message translates to:
  /// **'{hours} ó mért idő'**
  String polarMeasuredHours(String hours);

  /// A polár-táblázat lábjegyzete egy év nézetben (16a).
  ///
  /// In hu, this message translates to:
  /// **'A százalék a mért vízsebesség (STW) és a polár célsebességének aránya az adott szélszögre és -erősségre. A 100% nem plafon, hanem a historikus felső tized küszöbe.'**
  String get polarFootnote;

  /// A sor alcíme, ha 60 mp-nél kevesebb a mért idő (W2).
  ///
  /// In hu, this message translates to:
  /// **'kevés adat'**
  String get polarFewData;

  /// A sor alcíme, ha a szerver még nem számolta a versenyt (W2).
  ///
  /// In hu, this message translates to:
  /// **'még nincs számolva'**
  String get polarNotComputed;

  /// A frissítés alatti állapot sora (16d-2).
  ///
  /// In hu, this message translates to:
  /// **'Újraszámolás a szerveren — a korábbi értékek látszanak.'**
  String get polarStale;

  /// A szakasz mondata, ha a szerveren nincs polár (16d-3).
  ///
  /// In hu, this message translates to:
  /// **'Nincs polár a szerveren, ezért teljesítmény-százalék nem számolható.'**
  String get polarUnavailable;

  /// A polár-szakasz betöltési hibája (W2).
  ///
  /// In hu, this message translates to:
  /// **'A polár-adatok nem tölthetők be.'**
  String get polarLoadError;

  /// A részletező polár-blokkjának címe (16c).
  ///
  /// In hu, this message translates to:
  /// **'POLÁR'**
  String get polarDetailCaps;

  /// A részletező polár-fejlécének jobb slotja közelítő versenynél.
  ///
  /// In hu, this message translates to:
  /// **'≈ KÖZELÍTŐ'**
  String get polarDetailApproximateCaps;

  /// A részletező polár-fejlécének jobb slotja kevés adatnál.
  ///
  /// In hu, this message translates to:
  /// **'KEVÉS ADAT'**
  String get polarDetailFewDataCaps;

  /// A részletező polár-blokkjának rang-cellája.
  ///
  /// In hu, this message translates to:
  /// **'SZEZONBELI RANG'**
  String get polarDetailRankCaps;

  /// A szezonbeli rang mezőnye: a rangot kapott versenyek száma.
  ///
  /// In hu, this message translates to:
  /// **'/ {count}'**
  String polarDetailRankOf(int count);

  /// A részletező cellája: legjobb 5 mp.
  ///
  /// In hu, this message translates to:
  /// **'LEGJOBB 5 MP'**
  String get polarDetailBestCaps;

  /// A részletező cellája: a 90% fölötti idő aránya.
  ///
  /// In hu, this message translates to:
  /// **'90% FELETT'**
  String get polarDetailAbove90Caps;

  /// A részletező cellája: a 100% fölötti idő aránya.
  ///
  /// In hu, this message translates to:
  /// **'100% FELETT'**
  String get polarDetailAbove100Caps;

  /// A belépő képernyő felirata a cím fölött (17a, verzál).
  ///
  /// In hu, this message translates to:
  /// **'FORETACK'**
  String get signInBrandCaps;

  /// A belépő képernyő címe (17a).
  ///
  /// In hu, this message translates to:
  /// **'Lola versenyarchívum'**
  String get signInTitle;

  /// Halk sor a belépő képernyőn, ha munka közben járt le a belépés (ADR 0051 Addendum 7 P1).
  ///
  /// In hu, this message translates to:
  /// **'A belépés lejárt'**
  String get signInExpired;

  /// A QR-kód alatti felszólítás (17a).
  ///
  /// In hu, this message translates to:
  /// **'Olvasd be a Foretack appal'**
  String get signInScanPrompt;

  /// A QR-kép képernyőolvasó-címkéje (P6).
  ///
  /// In hu, this message translates to:
  /// **'Belépési QR-kód'**
  String get signInQrLabel;

  /// A beolvasott QR helyén álló doboz szövege (17c).
  ///
  /// In hu, this message translates to:
  /// **'Erősítsd meg a telefonodon'**
  String get signInConfirmOnPhone;

  /// A csatlakozási kérelem dobozának felirata (17d-1, verzál).
  ///
  /// In hu, this message translates to:
  /// **'KÉRELEM ELKÜLDVE'**
  String get signInJoinSentCaps;

  /// A csatlakozási kérelem dobozának szövege (17d-1).
  ///
  /// In hu, this message translates to:
  /// **'A tulajdonos jóváhagyására vár'**
  String get signInJoinAwaitingOwner;

  /// A felirat helyén, ha a megnyitott vagy csatlakozó kérés lejárt (17d-2).
  ///
  /// In hu, this message translates to:
  /// **'Lejárt — olvasd be újra'**
  String get signInQrExpired;

  /// A szerver nem érhető el (belépő képernyő, induló kapu).
  ///
  /// In hu, this message translates to:
  /// **'Nincs kapcsolat a szerverrel'**
  String get signInOffline;

  /// Link vissza a QR-belépéshez (17c, 17d-1, 17e).
  ///
  /// In hu, this message translates to:
  /// **'Vissza a QR-kódhoz'**
  String get signInBackToQr;

  /// Link a tartalék belépéshez (17a).
  ///
  /// In hu, this message translates to:
  /// **'Belépés jelszóval vagy helyreállító kóddal'**
  String get signInUseFallback;

  /// A tartalék mező címkéje (17e-1, verzál).
  ///
  /// In hu, this message translates to:
  /// **'JELSZÓ VAGY HELYREÁLLÍTÓ KÓD'**
  String get signInFallbackLabelCaps;

  /// A tartalék űrlap gombja (17e-1).
  ///
  /// In hu, this message translates to:
  /// **'Belépés'**
  String get signInSubmit;

  /// A hibás tartalék próba semleges szövege (17e-2).
  ///
  /// In hu, this message translates to:
  /// **'Nem sikerült belépni'**
  String get signInRejected;

  /// A túl sok próbálkozás utáni várakozás (17e-3); a perc száma mono betűvel jelenik meg.
  ///
  /// In hu, this message translates to:
  /// **'Próbáld újra {minutes} perc múlva'**
  String signInRetryInMinutes(int minutes);

  /// A név-menü gombjának tooltipje (17f).
  ///
  /// In hu, this message translates to:
  /// **'Fiók'**
  String get accountMenuTooltip;

  /// A tulajdonos szerepe a név-menüben (17f-1, verzál).
  ///
  /// In hu, this message translates to:
  /// **'TULAJDONOS'**
  String get accountRoleOwnerCaps;

  /// A legénység szerepe a név-menüben (17f-2, verzál).
  ///
  /// In hu, this message translates to:
  /// **'LEGÉNYSÉG'**
  String get accountRoleCrewCaps;

  /// A név-menü kijelentkezés-sora (17f).
  ///
  /// In hu, this message translates to:
  /// **'Kijelentkezés'**
  String get accountSignOut;

  /// Snackbar, ha a kijelentkezés nem érte el a szervert; a web belépve marad.
  ///
  /// In hu, this message translates to:
  /// **'Nem sikerült kijelentkezni. Próbáld újra.'**
  String get accountSignOutFailed;

  /// Az üres archívum szövege a legénységnek, feltöltésre hívás nélkül.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs verseny az archívumban.'**
  String get logEmptyCrew;
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
