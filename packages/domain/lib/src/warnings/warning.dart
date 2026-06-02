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
