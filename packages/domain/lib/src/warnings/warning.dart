import 'package:domain/src/warnings/warning_severity.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// A verseny közben megjeleníthető figyelmeztetések sealed hierarchiája
/// (ARCHITECTURE.md 11., ADR 0014).
///
/// Pure domain típus, Flutter és l10n nélkül. Minden leaf csak egy stabil
/// [codeId]-t (log/telemetria) és egy [severity]-t hordoz; a lokalizált
/// címet és leírást az apps/phone réteg adja exhaustive `switch`-csel a
/// sealed típuson (ADR 0014 D3), így új warning kihagyása fordítási hiba.
///
/// A [severity] szándékosan computed getter, nem ctor-mező: a v1
/// leafeknél konstans, de a halasztott, instancia-függő warningoknak
/// (pl. `BatteryLow`) így nem kell külön séma — a getter a payloadból is
/// számolhat majd (ADR 0014 D3).
@immutable
sealed class Warning extends Equatable {
  /// Base ctor; a v1 leafek payload nélküli, const jelzők.
  const Warning();

  /// Stabil, snake_case azonosító loghoz és telemetriához. NEM
  /// lokalizált — a kijelzett szöveg az apps/phone l10n-leképezésé.
  String get codeId;

  /// A megjelenítést vezérlő súlyosság (ADR 0014 D6).
  WarningSeverity get severity;

  @override
  bool? get stringify => true;
}

/// A YDWG-02 gateway nem csatlakozott — nincs élő műszer-adat
/// (ADR 0014 D5: `ConnectionStatus is! Connected`).
final class GatewayDisconnected extends Warning {
  /// Gateway-lekapcsolt jelző.
  const GatewayDisconnected();

  @override
  String get codeId => 'gateway_disconnected';

  @override
  WarningSeverity get severity => WarningSeverity.critical;

  @override
  List<Object?> get props => const [];
}

/// Nincs GPS-fix — a pozíció ismeretlen, így bearing/distance/ETA nem
/// számolható (ADR 0014 D5: `boatState.position == null`).
final class GpsSignalLost extends Warning {
  /// GPS-jel-vesztett jelző.
  const GpsSignalLost();

  @override
  String get codeId => 'gps_signal_lost';

  @override
  WarningSeverity get severity => WarningSeverity.critical;

  @override
  List<Object?> get props => const [];
}

/// A GPS-idő nincs szinkronban a valós idővel — az idő-cella nem
/// megbízható (ADR 0014 D7, ADR 0012 D5). A normál 4–6 mp Vulcan-
/// transzportkésés NEM vált ki ilyet.
final class GpsTimeUnsynced extends Warning {
  /// GPS-idő-szinkronhiány jelző.
  const GpsTimeUnsynced();

  @override
  String get codeId => 'gps_time_unsynced';

  @override
  WarningSeverity get severity => WarningSeverity.warning;

  @override
  List<Object?> get props => const [];
}

/// Nincs elég minta a szél-shift trendhez — a következő bójánál várható
/// TWA nem becsülhető (ADR 0014 D4: csak `RaceStatus.active` alatt jelez).
final class WindShiftTrendInsufficient extends Warning {
  /// Szél-shift-trend-elégtelen jelző.
  const WindShiftTrendInsufficient();

  @override
  String get codeId => 'wind_shift_trend_insufficient';

  @override
  WarningSeverity get severity => WarningSeverity.info;

  @override
  List<Object?> get props => const [];
}

/// Az iránytű (ZG100) gyanús: a heading tartósan eltér a haladási iránytól
/// (ADR 0020 D5). A heading-alapú kijelzések és a `MWD` ilyenkor gyanúsak,
/// de a derivált TWD (§6.5) és a predikció ettől függetlenül helyes.
final class SuspectHeadingWarning extends Warning {
  /// Gyanús-iránytű jelző.
  const SuspectHeadingWarning();
  @override
  String get codeId => 'suspect_heading';
  @override
  WarningSeverity get severity => WarningSeverity.warning;
  @override
  List<Object?> get props => const [];
}

/// Nincs használható polár-adat: a polár betöltése sikertelen (hiányzó, üres
/// vagy hibás asset; a `PolarRepository` `Err`-ága). Ilyenkor a cél-sebesség %
/// nem számítható (ADR 0028 C6). A no-go (van polár, de a cella `null`) NEM
/// ez — az normál állapot, nem warning. Info: csak a telefon-banneren jelez,
/// az órára a payload (ADR 0015) nem viszi (az csak a critical warningokat).
final class PolarMissing extends Warning {
  /// Polár-hiány jelzo.
  const PolarMissing();

  @override
  String get codeId => 'polar_missing';

  @override
  WarningSeverity get severity => WarningSeverity.info;

  @override
  List<Object?> get props => const [];
}

/// Sekély víz: az engine sekély-víz epizódja aktív, a mért mélység a
/// riasztási küszöb alatt van (ADR 0031 D4). A `depthMeters` az epizód
/// pillanatnyi mélysége.
///
/// Ez az első payloadot hordozó leaf, ezért a `props` itt nem üres: két
/// különböző mélységű riasztás NEM egyenlő. Szándékos — az óra-payload
/// change-detectje különben elnyelné a mélyülő epizód frissülését.
final class DepthWarning extends Warning {
  /// Sekély-víz jelző a pillanatnyi mélységgel.
  const DepthWarning(this.depthMeters);

  /// A riasztást kiváltó pillanatnyi mélység méterben.
  final double depthMeters;

  @override
  String get codeId => 'depth_shallow';

  @override
  WarningSeverity get severity => WarningSeverity.critical;

  @override
  List<Object?> get props => [depthMeters];
}
