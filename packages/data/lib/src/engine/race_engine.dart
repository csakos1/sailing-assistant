import 'dart:async';

import 'package:data/src/engine/race_snapshot.dart';
import 'package:data/src/engine/snapshot_logger.dart';
import 'package:data/src/nmea/client/raw_nmea_line_source.dart';
import 'package:domain/domain.dart';

/// A háttér-adatfolyam egy-tulajdonos orchestrátora (ADR 0017 D1).
///
/// Plain-Dart, Riverpod nélkül: az injektált [NmeaStream]-re iratkozik, a
/// domain-eseményeket a [BoatStateReducer] / [WindHistoryReducer]
/// segítségével élő állapottá foldol, a `tickSource` (default 1 Hz) minden
/// ütésénél újraszámolja a wind-shift trendet és a [MarkPrediction]-t, és
/// [RaceSnapshot]-ot emittál. A nyers mondatokat — ha a forrás egyúttal
/// [RawNmeaLineSource] — az injektált [TelemetryLogger]-nek adja át.
///
/// A `domain` + `data` rétegre épül, a hoszt (foreground service / izolátum)
/// nem szivárog ide (ADR 0016 D7) — ezért közvetlenül, `ProviderContainer`
/// nélkül replay-tesztelhető.
class RaceEngine {
  /// Engine az injektált forrással és telemetria-loggerrel. A `tickSource`
  /// teszt-seam: ha `null`, belső 1 Hz-es `Stream.periodic` jár.
  RaceEngine({
    required NmeaStream nmeaStream,
    required TelemetryLogger telemetryLogger,
    SnapshotLogger snapshotLogger = const _NoopSnapshotLogger(),
    Stream<DateTime>? tickSource,
    Duration windWindow = const Duration(minutes: 10),
    DateTime Function() now = DateTime.now,
  }) : _nmeaStream = nmeaStream,
       _telemetryLogger = telemetryLogger,
       _snapshotLogger = snapshotLogger,
       _windWindow = windWindow,
       _now = now,
       _tickSource =
           tickSource ??
           Stream<DateTime>.periodic(const Duration(seconds: 1), (_) => now());

  final NmeaStream _nmeaStream;
  final TelemetryLogger _telemetryLogger;
  final SnapshotLogger _snapshotLogger;
  final Stream<DateTime> _tickSource;
  final Duration _windWindow;
  final DateTime Function() _now;

  // Állapotmentes, megosztható domain-egységek (const példányok).
  static const _boatReducer = BoatStateReducer();
  static const _windReducer = WindHistoryReducer();
  static const _trend = CalculateWindShiftTrend();
  static const _predict = ComputeMarkPrediction();
  static const _derive = DeriveTrueWindDirection();
  static const _lookupTarget = LookupTargetSpeed();
  static const _computeVmg = ComputeVmg();
  static const _lookupTargetVmg = LookupTargetVmg();
  static const _computeVmgSteer = ComputeVmgSteerCorrection();
  static const _evaluateDepthAlert = EvaluateDepthAlert();

  // m/s → csomó: a LookupTargetSpeed kn-ben várja a TWS-t, a Speed m/s-ben.
  static const _knotsPerMps = 1.943844;

  final StreamController<RaceSnapshot> _snapshots =
      StreamController<RaceSnapshot>.broadcast();

  // Élő, foldolt állapot — egy-tulajdonos: csak az engine írja.
  late BoatState _boatState;
  WindData? _wind;
  List<WindObservation> _windHistory = const <WindObservation>[];
  // A stateless DeriveTrueWindDirection görgető párja (ADR 0020 D3):
  // csak a live becslés frissíti, egyébként az utolsó jót tartja.
  Bearing? _lastGoodTwd;
  // A legutóbbi TWD-derivációs minőség (ADR 0020 D7): a snapshotba kerül, hogy
  // a UI jelezhesse, mennyire friss a köv-bója-TWA-t tápláló szélirány.
  TwdQuality _lastTwdQuality = TwdQuality.unavailable;
  // A sekély-víz epizód állapota (ADR 0031 D4). Az engine tartja, nem a
  // task handler: stateful, és kijelző-off mellett is 1 Hz-en kell lépnie.
  DepthAlertState _depthAlert = const DepthAlertState();
  int _eventCount = 0;
  Race? _race;
  // A polár (a host tölti, az init-üzenet hozza, ADR 0028 Add. 3); null,
  // amíg nincs polár → a cél-sebesség mindig null.
  Polar? _polar;

  // A mark-rounding detektor (stateful, egy aktív bójához egy minimum-
  // profil). Megkerüléskor reseteljük; a léptetést a _maybeRoundMark
  // végzi (ADR 0017 A11).
  final MarkRoundingDetector _markRoundingDetector = MarkRoundingDetector();

  StreamSubscription<DomainEvent>? _eventSub;
  StreamSubscription<String>? _rawSub;
  StreamSubscription<DateTime>? _tickSub;

  /// A tick-enkénti pillanatképek folyama (a hoszt / UI-tükör fogyasztja).
  Stream<RaceSnapshot> get snapshots => _snapshots.stream;

  /// Elindítja az adatfolyamot a `race`-hez: feliratkozik az eseményekre
  /// (fold) és — ha a forrás [RawNmeaLineSource] — a nyers sorokra
  /// (telemetria), elindítja a tick-et, majd csatlakozik a forráshoz. A
  /// [BoatState] az app-órából seedel.
  Future<void> start(Race race, {Polar? polar}) async {
    _race = race;
    _polar = polar;
    _boatState = BoatState(lastUpdate: _now());

    _eventSub = _nmeaStream.events.listen(_onEvent);
    if (_nmeaStream case final RawNmeaLineSource rawSource) {
      _rawSub = rawSource.rawLines.listen(_onRawLine);
    }
    _tickSub = _tickSource.listen(_onTick);

    await _nmeaStream.connect();
  }

  /// Leállítja a feliratkozásokat és a tick-et, majd lekapcsolja a forrást. A
  /// telemetria záró flush-e a [dispose]-ban történik.
  Future<void> stop() async {
    await _eventSub?.cancel();
    await _rawSub?.cancel();
    await _tickSub?.cancel();
    _eventSub = null;
    _rawSub = null;
    _tickSub = null;
    await _nmeaStream.disconnect();
  }

  /// Végleg elenged: [stop], a telemetria-logger záró flush-e, és a
  /// snapshot-controller zárása. Idempotens. Az injektált [NmeaStream] teljes
  /// felszabadítása a composition root dolga (az interfészen nincs `dispose`).
  Future<void> dispose() async {
    await stop();
    await _telemetryLogger.dispose();
    await _snapshotLogger.dispose();
    if (!_snapshots.isClosed) {
      await _snapshots.close();
    }
  }

  /// A UI-tól érkező Start parancs alkalmazása az engine saját `_race`-én
  /// (A10/A13): `notStarted → active` az `at` időbélyeggel. No-op, ha
  /// nincs race vagy már nem `notStarted` — idempotens, a dup-parancs nem
  /// dob (a `Race.start` assertje csak notStartedre enged). A rounding
  /// által léptetett `activeMarkIndex` (induláskor 0) érintetlen marad.
  void applyStartCommand(DateTime at) {
    final race = _race;
    if (race == null || race.status != RaceStatus.notStarted) {
      return;
    }
    _race = race.start(at: at);
  }

  /// A UI-tól érkező Finish parancs alkalmazása (A10/A13):
  /// `active → finished` az `at` időbélyeggel. No-op, ha nincs race vagy
  /// nem `active`. A `finish` az indexet a domain-szabály szerint a
  /// végére állítja (`index == marks.length`), így az aktív bója `null`,
  /// és a mark-rounding nem léptet tovább.
  void applyFinishCommand(DateTime at) {
    final race = _race;
    if (race == null || race.status != RaceStatus.active) {
      return;
    }
    _race = race.finish(at: at);
  }

  /// A UI-t�l �rkez? manu�lis b�ja-megker�l�s parancs alkalmaz�sa: a
  /// haj�s k�zzel jelzi, hogy vette a b�j�t. Az�rt kell, mert pontatlan
  /// boja-koordin�t�n�l a haj� sosem �ri el a detektor 50 m-es k�sz�b�t,
  /// �gy az auto-rounding nem l�ptetne (az eg�sz versenyen az els? b�j�ra
  /// vinne). Az `at` az engine saj�t �r�ja (`_now`), egyezve a tick-alap�
  /// auto-�ttal. No-op, ha nincs race vagy nem `active` ? a
  /// `Race.roundCurrentMark` assertje csak activere enged, az utols� b�j�n
  /// a domain auto-finish-el. A detektort resetelj�k, hogy a k�zi l�ptet�s
  /// ut�n az �j b�j�hoz tiszta minimum-profilb�l induljon (mint a
  /// `_maybeRoundMark`).
  void applyRoundMarkCommand() {
    final race = _race;
    if (race == null || race.status != RaceStatus.active) {
      return;
    }
    _markRoundingDetector.reset();
    _race = race.roundCurrentMark(at: _now());
  }

  // Egyetlen esemény befoldolása az élő állapotba.
  void _onEvent(DomainEvent event) {
    _eventCount++;
    _boatState = _boatReducer(_boatState, event, _now());
    if (event case WindEvent(:final data)) {
      _wind = data;
      // TWD a COG + csúcs-relatív TWA-ból (ADR 0020): a MWD-alapú
      // trueDirectionGround megbízhatatlan a kalibrálatlan ZG100 miatt.
      final estimate = _derive(
        boatState: _boatState,
        wind: data,
        lastGoodTwd: _lastGoodTwd,
      );
      // A legutóbbi minőség a snapshotba (ADR 0020 D7): a held/unavailable is
      // eljut a UI-ig, nem csak a live.
      _lastTwdQuality = estimate.quality;
      // Csak a live becslés görgeti a lastGoodTwd-t; held/unavailable tartja.
      if (estimate.quality == TwdQuality.live) {
        _lastGoodTwd = estimate.twd;
      }
      final twd = estimate.twd;
      // unavailable -> twd null -> nem fűzünk observationt (history-kihagyás).
      if (twd != null) {
        _windHistory = _windReducer(
          _windHistory,
          WindObservation(
            twd: twd,
            timestamp: data.timestamp,
            twdQuality: estimate.quality,
          ),
        );
      }
    }
  }

  // Egy nyers sor telemetria-rekordként. Az üres sort kihagyjuk (a
  // TelemetryRecord nem enged üres rawSentence-t).
  void _onRawLine(String line) {
    final race = _race;
    if (race == null || line.isEmpty) {
      return;
    }
    unawaited(
      _telemetryLogger.log(
        TelemetryRecord(raceId: race.id, timestamp: _now(), rawSentence: line),
      ),
    );
  }

  // 1 Hz recompute: trend → prediction → snapshot emit.
  void _onTick(DateTime tick) {
    final race = _race;
    if (race == null || _snapshots.isClosed) {
      return;
    }
    // A predikció előtt léptetjük az aktív bóját, ha a hajó körözte (csak
    // active alatt, ADR 0017 A11) — a léptetett race-re prediktálunk.
    final steppedRace = _maybeRoundMark(race, tick);
    _race = steppedRace;

    final trend = _trend(history: _windHistory, window: _windWindow, now: tick);
    final prediction = _predict(
      activeMark: steppedRace.activeMarkOrNull,
      nextMark: steppedRace.nextMarkOrNull,
      boatState: _boatState,
      trend: trend,
      now: tick,
    );
    // A kapcsolat-állapotot egyszer olvassuk ki: a tick-en belül a
    // riasztás-elnyomás és a snapshot ugyanazt az értéket lássa.
    final connectionStatus = _nmeaStream.currentStatus;
    // A sekély-víz állapotgép (ADR 0031 D4). A mélységet lokálisba emeljük,
    // hogy a snapshotba írt érték pontosan az legyen, amit a gép látott.
    final depth = _boatState.depth;
    _depthAlert = _evaluateDepthAlert(
      previous: _depthAlert,
      depth: depth,
      isConnected: connectionStatus is Connected,
    );
    final targetSpeedKnots = _targetSpeedKnots();
    final vmgKnots = _vmgKnots();
    final targetVmg = _targetVmg();
    final targetVmgKnots = targetVmg?.vmgKnots;
    final vmgSteerCorrection = _vmgSteerCorrection(targetVmg);
    // A snapshotot lokális változóba emeljük: az emit után a
    // snapshot-logger ugyanazt a példányt kapja (ADR 0022 D4).
    final snapshot = RaceSnapshot(
      eventCount: _eventCount,
      boatState: _boatState,
      connectionStatus: connectionStatus,
      raceStatus: steppedRace.status,
      tickTime: tick,
      wind: _wind,
      prediction: prediction,
      windShiftTrend: trend,
      twdQuality: _lastTwdQuality,
      targetSpeedKnots: targetSpeedKnots,
      vmgKnots: vmgKnots,
      targetVmgKnots: targetVmgKnots,
      vmgSteerCorrection: vmgSteerCorrection,
      depthAlertMeters: _depthAlert.isActive ? depth?.meters : null,
      depthBuzzCounter: _depthAlert.buzzCounter,
    );
    _snapshots.add(snapshot);
    // unawaited + a logger internál try/catch: egy DB-hiba sem
    // szakíthatja meg a snapshot-streamet (defenzív elv).
    unawaited(_snapshotLogger.log(steppedRace.id, snapshot));
  }

  /// A polár-alapú cél-sebesség (kn) az élő szélből, vagy `null`, ha nincs
  /// betöltött polár, hiányzik a water-referenciájú szél, vagy a TWA a no-go
  /// alatt van (ADR 0028 Addendum 3). A `LookupTargetSpeed` kn-ben várja a
  /// TWS-t, a `Speed` viszont m/s — ezért konvertálunk.
  double? _targetSpeedKnots() {
    final polar = _polar;
    final wind = _wind;
    if (polar == null || wind == null) {
      return null;
    }
    final twa = wind.trueAngleWater;
    final tws = wind.trueSpeedWater;
    if (twa == null || tws == null) {
      return null;
    }
    return _lookupTarget(
      polar: polar,
      twaDegrees: twa.degrees,
      twsKnots: tws.metersPerSecond * _knotsPerMps,
    );
  }

  /// Az élő VMG (kn) a vízhez mért szélből és a hajósebességből, vagy `null`,
  /// ha hiányzik a water-referenciájú TWA vagy nincs sebesség. A sebesség STW,
  /// SOG-fallbackkel (ADR 0028 Addendum 3); a `Speed` m/s, a `ComputeVmg`
  /// kn-ben dolgozik, ezért konvertálunk.
  double? _vmgKnots() {
    final wind = _wind;
    if (wind == null) {
      return null;
    }
    final twa = wind.trueAngleWater;
    if (twa == null) {
      return null;
    }
    final speed = _boatState.speedThroughWater ?? _boatState.speedOverGround;
    if (speed == null) {
      return null;
    }
    return _computeVmg(
      boatSpeedKnots: speed.metersPerSecond * _knotsPerMps,
      twaDegrees: twa.degrees,
    );
  }

  /// A polár-alapú target VMG és a hozzá tartozó optimum-szög az élő
  /// szélből ([TargetVmg]), vagy `null`, ha nincs betöltött polár,
  /// hiányzik a water-referenciájú szél, vagy a sávban nincs polár-adat
  /// (ADR 0028 Addendum 4). A fel-/hátszél a pillanatnyi `|TWA|`-ból
  /// dől el, az élő VMG-vel konzisztens előjelért (E4). Egy pásztázás
  /// adja a target VMG-t ÉS a steer-optimumot (SSOT, F4). A
  /// `LookupTargetVmg` kn-ben várja a TWS-t, a `Speed` viszont m/s.
  TargetVmg? _targetVmg() {
    final polar = _polar;
    final wind = _wind;
    if (polar == null || wind == null) {
      return null;
    }
    final twa = wind.trueAngleWater;
    final tws = wind.trueSpeedWater;
    if (twa == null || tws == null) {
      return null;
    }
    return _lookupTargetVmg(
      polar: polar,
      twaDegrees: twa.degrees,
      twsKnots: tws.metersPerSecond * _knotsPerMps,
    );
  }

  /// A VMG-optimum szögre vezető steer-korrekció (Angle) az élő szélből,
  /// vagy `null`, ha nincs target-VMG ([targetVmg] null), vagy a TWD
  /// minősége nem `live`. Held/weak TWD-n a korrekciót elnyomjuk
  /// (forduló-elnyomás, F7): elavult szélszögre vezetne. A no-go-kaput
  /// a `ComputeVmgSteerCorrection` maga kezeli (F6).
  Angle? _vmgSteerCorrection(TargetVmg? targetVmg) {
    if (targetVmg == null || _lastTwdQuality != TwdQuality.live) {
      return null;
    }
    final twa = _wind?.trueAngleWater;
    if (twa == null) {
      return null;
    }
    return _computeVmgSteer(
      currentTwa: twa,
      optimumTwaMagnitude: targetVmg.optimumTwaDegrees,
    );
  }

  // A mark-rounding detektor egy tickje (ADR 0017 A11). Csak active
  // státusz + ismert pozíció + aktív bója esetén léptet; megkerüléskor a
  // következő bójára vált és reseteli a detektort. DB-visszaírás nincs
  // (ADR 0016 D6) — a progressziót a telemetria + snapshot rögzíti.
  Race _maybeRoundMark(Race race, DateTime tick) {
    if (race.status != RaceStatus.active) {
      return race;
    }
    final position = _boatState.position;
    final activeMark = race.activeMarkOrNull;
    if (position == null || activeMark == null) {
      return race;
    }
    if (_markRoundingDetector.tick(position, activeMark)) {
      _markRoundingDetector.reset();
      return race.roundCurrentMark(at: tick);
    }
    return race;
  }
}

/// No-op SnapshotLogger: a RaceEngine ctor alapértelmezése. A replay/
/// teszt/prediction_probe út DB-írás nélkül fut; a phone composition
/// root ad valódi SnapshotLoggerImpl-t (ADR 0022 D3).
class _NoopSnapshotLogger implements SnapshotLogger {
  const _NoopSnapshotLogger();

  @override
  Future<void> log(String raceId, RaceSnapshot snapshot) async {}

  @override
  Future<void> dispose() async {}
}
