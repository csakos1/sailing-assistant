// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get liveOpen => 'Élő nézet';

  @override
  String get liveNoActiveRace => 'Nincs aktív verseny';

  @override
  String get liveStale => 'ELAVULT';

  @override
  String get liveTwaNow => 'TWA MOST';

  @override
  String get liveTwaNext => 'TWA KÖV.';

  @override
  String get liveTwdHeld => 'TARTOTT';

  @override
  String get liveBearing => 'BEARING';

  @override
  String get liveCorrection => 'KORREKCIÓ';

  @override
  String get liveDistance => 'TÁV';

  @override
  String get liveEta => 'ETA';

  @override
  String get liveStop => 'Leállítás';

  @override
  String get liveStopTitle => 'Verseny leállítása';

  @override
  String get liveStopMessage =>
      'Biztosan leállítod az élő követést? A háttér-engine leáll.';

  @override
  String get liveStopCancel => 'Mégse';

  @override
  String get liveStopConfirm => 'Leállítás';

  @override
  String get liveRoundMark => 'Bója megvan';

  @override
  String get liveRoundMarkTitle => 'Bója megkerülve?';

  @override
  String liveRoundMarkMessage(String mark) {
    return 'Megjelölöd a(z) $mark át megkerültnek?';
  }

  @override
  String get liveRoundMarkMessageGeneric =>
      'Megjelölöd a jelenlegi bóját megkerültnek?';

  @override
  String get liveRoundMarkCancel => 'Mégse';

  @override
  String get liveRoundMarkConfirm => 'Megvan';

  @override
  String liveServiceError(String message) {
    return 'Háttér-engine hiba: $message';
  }

  @override
  String get etaMinutesUnit => 'perc';

  @override
  String get warningGatewayDisconnected => 'Nincs kapcsolat a műszerekkel';

  @override
  String get warningGpsSignalLost => 'Nincs GPS-jel';

  @override
  String get warningGpsTimeUnsynced => 'GPS-idő nincs szinkronban';

  @override
  String get warningWindShiftTrendInsufficient => 'Kevés széladat a trendhez';

  @override
  String get warningSuspectHeading => 'Iránytű gyanús – heading és irány eltér';

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

  @override
  String get setupTitle => 'Új verseny';

  @override
  String get setupRaceNameLabel => 'Verseny neve';

  @override
  String get setupRaceNameRequired => 'Adj meg egy nevet.';

  @override
  String get setupMarksSection => 'BÓJÁK';

  @override
  String get setupNoMarksToggle => 'Bója nélküli verseny';

  @override
  String get setupNoMarksHint =>
      'A track és a target speed rögzül; bearing, ETA és predikció nem lesz.';

  @override
  String setupMarkHeader(int number) {
    return '$number. bója';
  }

  @override
  String get setupMarkNameLabel => 'Bója neve';

  @override
  String get setupMarkNameRequired => 'Adj meg egy nevet.';

  @override
  String get setupLatitudeLabel => 'Szélesség (°)';

  @override
  String get setupLongitudeLabel => 'Hosszúság (°)';

  @override
  String get setupInvalidNumber => 'Érvénytelen szám.';

  @override
  String get setupLatitudeOutOfRange =>
      'A szélesség -90 és 90 fok között lehet.';

  @override
  String get setupLongitudeOutOfRange =>
      'A hosszúság -180 és 180 fok között lehet.';

  @override
  String get setupCoordinateUnrecognized => 'Ismeretlen koordináta-formátum.';

  @override
  String get setupCoordinateComponentRange =>
      'A perc és a másodperc 0 és 60 között lehet.';

  @override
  String get setupCoordinateCardinalMismatch =>
      'Az égtáj-betű nem illik ehhez a mezőhöz.';

  @override
  String get setupAddMark => 'Bója hozzáadása';

  @override
  String get setupRemoveMark => 'Bója törlése';

  @override
  String get setupReorderHandle => 'Sorrend áthelyezése';

  @override
  String get setupSave => 'Mentés';

  @override
  String get editTitle => 'Verseny szerkesztése';

  @override
  String get detailEdit => 'Szerkesztés';

  @override
  String get raceStatusNotStarted => 'Nem indult';

  @override
  String get raceStatusActive => 'Folyamatban';

  @override
  String get raceStatusFinished => 'Befejezve';

  @override
  String get detailStart => 'Indítás';

  @override
  String get detailFinish => 'Befejezés';

  @override
  String get detailDelete => 'Törlés';

  @override
  String get detailDeleteTitle => 'Verseny törlése';

  @override
  String get detailDeleteMessage => 'Biztosan törlöd ezt a versenyt?';

  @override
  String get detailDeleteCancel => 'Mégse';

  @override
  String get detailDeleteConfirm => 'Törlés';

  @override
  String get listTitle => 'VERSENYEK';

  @override
  String get listEmpty =>
      'Még nincs verseny. Indíts egyet az Új verseny gombbal.';

  @override
  String get listError => 'Nem sikerült betölteni a versenyeket.';

  @override
  String get listAddRace => 'Új verseny';

  @override
  String get logTitle => 'Versenynapló';

  @override
  String listMarkCount(int count) {
    return '$count bója';
  }

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
  String get logYearSheetTitle => 'Év';

  @override
  String get logStatTimeCaps => 'VÍZEN TÖLTÖTT';

  @override
  String get logStatDistanceCaps => 'ÖSSZ. TÁV';

  @override
  String get logStatRecordCaps => 'REKORD';

  @override
  String get liveCorrectionRight => 'jobbra';

  @override
  String get liveCorrectionLeft => 'balra';

  @override
  String liveVmgTarget(String value) {
    return 'cél $value';
  }

  @override
  String get liveVmg => 'VMG';

  @override
  String get liveTargetSpeed => 'CÉL-SEB.';

  @override
  String get warningPolarMissing => 'Nincs polár-adat';

  @override
  String warningDepthShallow(String depth) {
    return 'Sekély víz: $depth m';
  }

  @override
  String get setupPickFromLibrary => 'Korábbi bóják';

  @override
  String get setupPickFromLibraryTitle => 'KORÁBBI BÓJÁK';

  @override
  String get setupPickFromLibraryEmpty => 'Még nincs mentett bója.';

  @override
  String get setupPickFromLibrarySearch => 'Keresés név szerint...';

  @override
  String get setupPickFromLibraryNoMatch => 'Nincs találat erre a névre.';

  @override
  String get detailCourseLabel => 'PÁLYA';

  @override
  String get detailAnalysisTitle => 'Post-race elemzés';

  @override
  String get detailAnalysisEmpty => 'Nincs elemzési adat ehhez a versenyhez.';

  @override
  String get detailAnalysisError => 'Nem sikerült betölteni az elemzést.';

  @override
  String get detailAnalysisAvgDelta => 'átlag |Δ|';

  @override
  String get detailAnalysisBandRatio => 'sávon belül';

  @override
  String get detailAnalysisAvgLead => 'átlag lead';

  @override
  String get detailAnalysisPredicted => 'jósolt';

  @override
  String get detailAnalysisActual => 'bója';

  @override
  String get detailAnalysisReliable => 'megbízható';

  @override
  String get detailAnalysisBeforeMark => 'a bója előtt';

  @override
  String get detailTrackEmpty => 'Nincs track-adat ehhez a versenyhez.';

  @override
  String get detailTrackMaxSpeed => 'max sebesség';

  @override
  String get detailTrackAvgSpeed => 'átlag sebesség';

  @override
  String get detailTrackDistance => 'megtett út';

  @override
  String get detailTrackLegendTitle => 'sebesség (kn)';

  @override
  String get detailTrackLegendUnknown => 'nincs adat';

  @override
  String get detailTrackOpenFullscreen => 'Track nagyítása';

  @override
  String exportImageDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get trackExportAction => 'Kép megosztása';

  @override
  String get trackExportTileWarningTitle => 'Hiányos térkép';

  @override
  String get trackExportTileWarningBody =>
      'A térkép egyes csempéi nem töltődtek be, ezért a megosztott képen fehér foltok lesznek. Így is exportálod?';

  @override
  String get trackExportTileWarningCancel => 'Mégsem';

  @override
  String get trackExportTileWarningConfirm => 'Exportálás így is';

  @override
  String get trackExportErrorCapture => 'A kép elkészítése nem sikerült.';

  @override
  String get trackExportErrorStorage =>
      'Nem sikerült ideiglenes fájlt írni a képnek.';

  @override
  String get trackExportErrorShare => 'A megosztás nem indult el.';

  @override
  String get safetyMapTitle => 'Biztonsági térkép';

  @override
  String get safetyMapNoPosition => 'Nincs pozíció-adat a műszerekről.';

  @override
  String get safetyMapOpen => 'Biztonsági térkép';

  @override
  String get safetyMapRecentre => 'Hajó középre';

  @override
  String get webScanTooltip => 'QR-kód beolvasása';

  @override
  String get webScanHint => 'Olvasd be a weboldal QR-kódját';

  @override
  String get webScanCameraDenied => 'A beolvasáshoz kamera-engedély kell';

  @override
  String get webScanCameraFailed => 'A kamera nem indult el';

  @override
  String get webScanRetry => 'Újra';

  @override
  String get webScanClose => 'Bezárás';

  @override
  String get webScanNotForetackTitle => 'Ez nem Foretack-kód';

  @override
  String get webScanNotForetackMessage =>
      'Olvasd be a weboldalon vagy a szerveren mutatott kódot.';

  @override
  String get webScanUnsupportedTitle => 'Frissítsd a Foretack appot';

  @override
  String get webScanUnsupportedMessage =>
      'Ezt a kódot az app egy újabb verziója érti.';

  @override
  String get webScanExpiredTitle => 'Lejárt QR-kód';

  @override
  String get webScanExpiredMessage =>
      'Olvasd be a weboldalon látható új kódot.';

  @override
  String get webScanExpiredEnrollMessage =>
      'Kérj új regisztrációs kódot a szerveren (CLI).';

  @override
  String get webScanForeignTitle => 'Ez nem a te Foretack-szervered';

  @override
  String get webScanForeignMessage => 'A kód ehhez tartozik:';

  @override
  String get webScanNoConnectionTitle => 'Nincs hálózat';

  @override
  String get webScanNoConnectionMessage =>
      'A belépéshez a telefonnak el kell érnie a szervert.';

  @override
  String get webScanTooManyTitle => 'Túl sok próbálkozás';

  @override
  String get webScanRevokedTitle => 'Ez a telefon vissza lett vonva';

  @override
  String get webScanRevokedCrewMessage =>
      'Kérj új csatlakozást; a tulajdonos hagyja jóvá.';

  @override
  String get webScanRevokedOwnerMessage =>
      'Regisztráld újra a telefont a szerveren (CLI).';

  @override
  String get webScanRequestJoin => 'Csatlakozás kérése';

  @override
  String get webScanBiometricsUnavailableTitle =>
      'Nincs beállított ujjlenyomat';

  @override
  String get webScanBiometricsUnavailableMessage =>
      'Az aláíráshoz ujjlenyomat kell. Állíts be egyet a telefon beállításaiban.';

  @override
  String get webScanLockedOutTitle => 'Az ujjlenyomat zárolva';

  @override
  String get webScanLockedOutMessage =>
      'Túl sok sikertelen próba. Oldd fel a telefont, és próbáld újra.';

  @override
  String get webScanSigningFailedTitle => 'Nem sikerült aláírni';

  @override
  String get webScanSigningFailedMessage => 'Próbáld újra.';

  @override
  String get webPromptLoginTitle => 'Belépés a Foretack webre';

  @override
  String get webPromptEnrollTitle => 'Telefon regisztrálása';

  @override
  String get webPromptCancel => 'Mégse';

  @override
  String get webLoginDone => 'Belépve a webre';

  @override
  String get webReplaceTitle => 'Fiók cseréje';

  @override
  String get webReplaceSameMessage =>
      'Új regisztráció. A régi eszköz a szerveren aktív marad, amíg vissza nem vonod.';

  @override
  String get webReplaceCancel => 'Mégse';

  @override
  String get webReplaceConfirm => 'Folytatás';

  @override
  String get webEnrollTitle => 'Regisztráció';

  @override
  String get webRoleOwner => 'TULAJDONOS';

  @override
  String get webRoleCrew => 'LEGÉNYSÉG';

  @override
  String get webEnrollDone => 'Telefon regisztrálva';

  @override
  String get webEnrollServer => 'Szerver';

  @override
  String get webEnrollAccount => 'Fiók';

  @override
  String get webEnrollPhone => 'Telefon';

  @override
  String get webEnrollToCodes => 'Tovább a helyreállító kódokhoz';

  @override
  String get webCodesTitle => 'Helyreállító kódok';

  @override
  String get webCodesNote =>
      'Csak most látszanak. Mentsd el őket biztos helyre — mindegyik egyszer használható.';

  @override
  String get webCodesCopy => 'Másolás';

  @override
  String get webCodesCopied => 'Kódok a vágólapon';

  @override
  String get webCodesSaved => 'Elmentettem';

  @override
  String get webScanExpiredJoinMessage =>
      'Olvasd be újra a QR-kódot; a neved megmaradt.';

  @override
  String get webPromptJoinTitle => 'Csatlakozás a Lola archívumához';

  @override
  String get webJoinTitle => 'Csatlakozás';

  @override
  String get webJoinHeading => 'Csatlakozás a Lola archívumához';

  @override
  String get webJoinNameLabel => 'NEVED';

  @override
  String get webJoinNameInvalid => '1–40 karakter, sortörés nélkül';

  @override
  String get webJoinSubmit => 'Kérelem küldése';

  @override
  String get webJoinSentLabel => 'KÉRELEM ELKÜLDVE';

  @override
  String get webJoinWaiting => 'Várj a tulajdonos jóváhagyására';

  @override
  String get webJoinName => 'Név';

  @override
  String get webJoinPhone => 'Telefon';

  @override
  String get webJoinSentAt => 'Elküldve';

  @override
  String get webJoinExpiresIn => 'Lejár';

  @override
  String get webJoinNotApproved => 'A kérelmet nem hagyták jóvá, vagy lejárt.';

  @override
  String get webJoinApprovedNotice => 'Csatlakoztál a Lola archívumához';

  @override
  String get webJoinNotApprovedNotice =>
      'A csatlakozási kérelmet nem hagyták jóvá, vagy lejárt.';

  @override
  String webJoinRemaining(int hours, int minutes) {
    return '$hours ó $minutes p';
  }

  @override
  String webScanTooManyMessage(int minutes) {
    return 'Próbáld újra $minutes perc múlva.';
  }

  @override
  String webReplaceForeignMessage(String current, String next) {
    return 'Ez a telefon a(z) $current szerveren van regisztrálva. Lecseréled erre: $next?';
  }

  @override
  String get webMenuTooltip => 'Webes hozzáférés';

  @override
  String get webMenuSection => 'WEBES HOZZÁFÉRÉS';

  @override
  String get webMenuSessions => 'Webes belépések';

  @override
  String get webBannerPassword => 'Belépés jelszóval';

  @override
  String get webBannerRecoveryCode => 'Belépés helyreállító kóddal';

  @override
  String get webBannerForeignCountry => 'Belépés más országból';

  @override
  String webBannerOtherUser(String name, String title) {
    return '$name · $title';
  }

  @override
  String webBannerAggregate(int count) {
    return '$count gyanús belépés';
  }

  @override
  String get webBannerAcknowledge => 'Rendben';

  @override
  String get webBannerSignOut => 'Kiléptetés';

  @override
  String get webSessionsTitle => 'Webes belépések';

  @override
  String webSessionsSelf(String name) {
    return '$name · TE';
  }

  @override
  String get webSessionsFallback => 'Tartalék-belépés';

  @override
  String get webSessionsForeignCountry => 'Belépés más országból';

  @override
  String webSessionsSignedIn(String when) {
    return 'belépett $when';
  }

  @override
  String webSessionsActive(String ago) {
    return 'aktív $ago';
  }

  @override
  String get webSessionsSignOut => 'Kiléptetés';

  @override
  String get webSessionsEmpty => 'Nincs aktív webes belépés';

  @override
  String get webSessionsGeoIp => 'IP-hely: DB-IP';

  @override
  String get webModeQr => 'QR';

  @override
  String get webModePassword => 'JELSZÓ';

  @override
  String get webModeRecoveryCode => 'KÓD';

  @override
  String get webUnknownBrowser => 'Ismeretlen böngésző';

  @override
  String get webNoConnection => 'Nincs kapcsolat a szerverrel';

  @override
  String get webNoLongerValid => 'Ez már nem érvényes';

  @override
  String get webActionFailed => 'Nem sikerült';

  @override
  String webTimeToday(String time) {
    return 'ma $time';
  }

  @override
  String webTimeYesterday(String time) {
    return 'tegnap $time';
  }

  @override
  String webTimeThisYear(String month, int day) {
    return '$month $day.';
  }

  @override
  String webTimeOlder(int year, String month, int day) {
    return '$year. $month $day.';
  }

  @override
  String get webMonthsShort =>
      'jan.|febr.|márc.|ápr.|máj.|jún.|júl.|aug.|szept.|okt.|nov.|dec.';

  @override
  String get webAgoNow => 'most';

  @override
  String webAgoMinutes(int count) {
    return '$count perce';
  }

  @override
  String webAgoHours(int count) {
    return '$count órája';
  }

  @override
  String webAgoDays(int count) {
    return '$count napja';
  }
}
