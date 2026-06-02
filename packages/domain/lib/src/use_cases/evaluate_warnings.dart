import 'package:domain/src/entities/boat_state.dart';
import 'package:domain/src/entities/race_status.dart';
import 'package:domain/src/entities/wind_shift_trend.dart';
import 'package:domain/src/repositories/connection_status.dart';
import 'package:domain/src/warnings/warning.dart';
import 'package:meta/meta.dart';

/// Pure use case: a verseny aktuális állapotából előállítja az éppen
/// aktív [Warning]-ök listáját (ARCHITECTURE.md 11., ADR 0014 D1/D2/D7).
///
/// **Pure.** Nincs állapota, nincs side effect; ugyanaz az input mindig
/// ugyanazt a listát adja, mockolás nélkül exhaustive-an tesztelhető — a
/// `ComputeMarkPrediction` mintája. Időt NEM kap: egyik v1 szabály sem
/// idő-alapú. Az idő-szinkron állapotát a hívó a provider-határon már
/// primitívekre bontotta (`isTimeUnsynced` / `timeStreamDrift`, ADR 0012
/// DD2); a `now`-input a halasztott `StaleData`-val tér majd vissza.
///
/// **Gating és sorrend.** Ha a gateway nem csatlakozott
/// (`connectionStatus is! Connected`), CSAK a [GatewayDisconnected] tér
/// vissza — élő feed nélkül a GPS/szél-szabályok zaj, ezért elnyomjuk őket
/// (ADR 0014 D5). Csatlakozott állapotban a három downstream szabály
/// függetlenül értékelődik, fix prioritási (egyben severity-csökkenő)
/// sorrendben: GPS-jel → GPS-idő → szél-trend.
@immutable
class EvaluateWarnings {
  /// Létrehozás opcionális [timeDriftThreshold]-override-tal (default
  /// 10 mp, ADR 0014 D7). A ctor const, az osztály `@immutable`.
  const EvaluateWarnings({
    Duration timeDriftThreshold = const Duration(seconds: 10),
  }) : _timeDriftThreshold = timeDriftThreshold;

  /// Abszolút drift-küszöb, ami FÖLÖTT a GPS-idő nem-szinkronnak számít.
  /// A normál 4–6 mp Vulcan-transzportkésés ez alatt marad.
  final Duration _timeDriftThreshold;

  /// A [connectionStatus] / [boatState] / [windShiftTrend] / [raceStatus]
  /// és az idő-szinkron primitívek ([isTimeUnsynced], [timeStreamDrift])
  /// alapján kiszámolt aktív warningok. Üres lista = nincs figyelmeztetés.
  List<Warning> call({
    required ConnectionStatus connectionStatus,
    required BoatState boatState,
    required WindShiftTrend? windShiftTrend,
    required RaceStatus raceStatus,
    required bool isTimeUnsynced,
    required Duration? timeStreamDrift,
  }) {
    // Gateway-gating: élő feed nélkül egyetlen, egyértelmű critical jelzés
    // — a downstream GPS/szél-warningokat elnyomjuk (ADR 0014 D5).
    if (connectionStatus is! Connected) {
      return const [GatewayDisconnected()];
    }

    final warnings = <Warning>[];

    if (boatState.position == null) {
      warnings.add(const GpsSignalLost());
    }

    // Szigorú >: a pontosan küszöbnyi (default 10 mp) eltérés még nem
    // riaszt, így a normál 4–6 mp transzportkésés alatta marad.
    final isDriftOverThreshold =
        timeStreamDrift != null && timeStreamDrift.abs() > _timeDriftThreshold;
    if (isTimeUnsynced || isDriftOverThreshold) {
      warnings.add(const GpsTimeUnsynced());
    }

    // Rajt előtt a trend hiánya normális; csak aktív versenyben jelzünk.
    if (windShiftTrend == null && raceStatus == RaceStatus.active) {
      warnings.add(const WindShiftTrendInsufficient());
    }

    return warnings;
  }
}
