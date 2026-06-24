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
  String get liveStale => 'Elavult';

  @override
  String get liveTwaNow => 'TWA most';

  @override
  String get liveTwaNext => 'TWA köv.';

  @override
  String get liveTwdHeld => 'tartott';

  @override
  String get liveBearing => 'Bearing';

  @override
  String get liveCorrection => 'Korrekció';

  @override
  String get liveDistance => 'Táv';

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
  String get listTitle => 'Versenyek';

  @override
  String get listEmpty => 'Még nincs verseny. Adj hozzá egyet a + gombbal.';

  @override
  String get listError => 'Nem sikerült betölteni a versenyeket.';

  @override
  String get listAddRace => 'Új verseny';

  @override
  String listMarkCount(int count) {
    return '$count bója';
  }

  @override
  String get liveVmg => 'VMG';

  @override
  String get liveTargetSpeed => 'Cél-seb.';

  @override
  String get warningPolarMissing => 'Nincs polár-adat';
}
