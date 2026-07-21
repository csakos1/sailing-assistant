import 'package:domain/src/entities/boat_state.dart';
import 'package:domain/src/entities/race_status.dart';
import 'package:domain/src/entities/wind_shift_trend.dart';
import 'package:domain/src/repositories/connection_status.dart';
import 'package:domain/src/value_objects/speed.dart';
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
/// (ADR 0014 D5). Csatlakozott állapotban a downstream szabályok
/// függetlenül értékelődnek, fix prioritási (egyben severity-csökkenő)
/// sorrendben: sekély víz → GPS-jel → GPS-idő → iránytű → szél-trend →
/// polár.
@immutable
class EvaluateWarnings {
  /// Létrehozás opcionális [timeDriftThreshold]-override-tal (default
  /// 10 mp, ADR 0014 D7). A ctor const, az osztály `@immutable`.
  const EvaluateWarnings({
    Duration timeDriftThreshold = const Duration(seconds: 10),
    Speed headingCheckMinSpeed = const Speed(metersPerSecond: 1.0289),
    double headingDiscrepancyThresholdDeg = 35,
  }) : _timeDriftThreshold = timeDriftThreshold,
       _headingCheckMinSpeed = headingCheckMinSpeed,
       _headingDiscrepancyThresholdDeg = headingDiscrepancyThresholdDeg;

  /// Abszolút drift-küszöb, ami FÖLÖTT a GPS-idő nem-szinkronnak számít.
  /// A normál 4–6 mp Vulcan-transzportkésés ez alatt marad.
  final Duration _timeDriftThreshold;

  /// SOG-küszöb, ami FÖLÖTT a heading/COG-eltérést gyanúsnak vesszük
  /// (alap 2.0 kn = 1.0289 m/s, ADR 0020 D5).
  final Speed _headingCheckMinSpeed;

  /// A heading és a COG közti eltérés gyanú-küszöbe fokban (alap 35°).
  final double _headingDiscrepancyThresholdDeg;

  /// A [connectionStatus] / [boatState] / [windShiftTrend] / [raceStatus],
  /// az idő-szinkron primitívek ([isTimeUnsynced], [timeStreamDrift]) és a
  /// [isPolarMissing] (a polár betöltése sikertelen), valamint a
  /// [depthAlertMeters] (az engine sekély-víz epizódja; `null` = nincs
  /// aktív epizód) alapján kiszámolt aktív warningok. Üres lista = nincs
  /// figyelmeztetés.
  List<Warning> call({
    required ConnectionStatus connectionStatus,
    required BoatState boatState,
    required WindShiftTrend? windShiftTrend,
    required RaceStatus raceStatus,
    required bool isTimeUnsynced,
    required Duration? timeStreamDrift,
    required bool isPolarMissing,
    required double? depthAlertMeters,
  }) {
    // Gateway-gating: élő feed nélkül egyetlen, egyértelmű critical jelzés
    // — a downstream GPS/szél-warningokat elnyomjuk (ADR 0014 D5).
    if (connectionStatus is! Connected) {
      return const [GatewayDisconnected()];
    }

    final warnings = <Warning>[];

    // A lista ELEJÉN: a zátonyveszély az egyetlen olyan critical jelzés,
    // ami azonnali kormánymozdulatot kíván (ADR 0031 D4). Külön gate nem
    // kell — az engine az epizód-állapotgépet disconnectkor reseteli,
    // ezért a null önmagában jelenti, hogy nincs aktív riasztás.
    if (depthAlertMeters != null) {
      warnings.add(DepthWarning(depthAlertMeters));
    }

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
    // Iránytű gyanús: a heading tartósan eltér a haladási iránytól (ADR
    // 0020 D5). A ZG100 heading-függő hibáját jelzi; a derivált TWD helyes.
    final hdg = boatState.headingTrue;
    final cog = boatState.courseOverGround;
    final sog = boatState.speedOverGround;
    if (hdg != null &&
        cog != null &&
        sog != null &&
        sog.metersPerSecond >= _headingCheckMinSpeed.metersPerSecond &&
        (hdg - cog).degrees.abs() >= _headingDiscrepancyThresholdDeg) {
      warnings.add(const SuspectHeadingWarning());
    }

    // Rajt előtt a trend hiánya normális; csak aktív versenyben jelzünk.
    if (windShiftTrend == null && raceStatus == RaceStatus.active) {
      warnings.add(const WindShiftTrendInsufficient());
    }

    // Nincs használható polár (hiányzó/hibás asset) → a cél-sebesség %
    // nem számítható. Info: a no-go (van polár, de üres cella) NEM ide
    // tartozik. Sorrend: a másik info (szél-trend) után, determinisztikusan.
    if (isPolarMissing) {
      warnings.add(const PolarMissing());
    }

    return warnings;
  }
}
