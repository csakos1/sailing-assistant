import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ui' show Locale;

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:phone/app/geolocator_gnss_clock.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/app/true_time_manager.dart';
import 'package:phone/engine/engine_gateway_host.dart';
import 'package:phone/features/live_race/warning_l10n.dart';
import 'package:phone/features/watch_sync/watch_payload_builder.dart';
import 'package:phone/features/watch_sync/watch_sync_controller.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:shared/shared.dart';

/// A háttér-izolátum belépési pontja.
///
/// A `@pragma('vm:entry-point')` kötelező: a plugin külön izolátumban hívja, ahol
/// a tree-shaking egyébként eltávolítaná.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(RaceEngineTaskHandler());
}

/// A háttér-feladat: az `onStart`-ban felépíti a [RaceEngine]-t (NMEA TCP +
/// domain-compute + telemetria), de NEM indítja — előbb egy `{type:'ready'}`
/// jelet küld a hostnak (ready-kézfogás, ADR 0017 A13). A host erre küldi a
/// teljes [Race] initet (`{type:'init', race:…}`), amire az engine elindul;
/// futás közben a `{type:'start'|'finish', at}` parancsokat a saját `_race`-én
/// alkalmazza.
///
/// A telemetria a háttér-engine **saját, WAL-módú** [AppDatabase.secondary]
/// kapcsolatára íródik (ADR 0017 D6): az izolátum a composition root, ezért itt
/// nyitjuk a kapcsolatot, és a [TelemetryLoggerImpl]-en át injektáljuk az
/// engine-be — az engine maga DB-agnosztikus marad. A teardownnál a záró flush
/// (`engine.dispose()`) UTÁN zárjuk a kapcsolatot (graceful finish-then-stop).
///
/// Minden engine-snapshot `toJson()`-ja a plugin-csatornán JSON-stringként megy
/// a UI-izolátumnak; az engine a saját 1 Hz-es timeréről ketyeg, nem az
/// `onRepeatEvent`-ről (`eventAction: nothing()`).
///
/// Az **óra-push** (ADR 0017 A14) is itt fut: minden snapshotra a service-
/// izolátumbeli [TrueTimeManager] (GNSS) + [EvaluateWarnings] + a
/// `buildWatchPayload` összeállítja a [WatchPayload]-ot, a [WatchSyncController]
/// change-detectel, és a transporton küld. e2.2b-ben a transport még csak logol;
/// a natív Data Layer-t az e3 köti be.
class RaceEngineTaskHandler extends TaskHandler {
  Nmea0183TcpClient? _client;
  AppDatabase? _db;
  RaceEngine? _engine;
  StreamSubscription<RaceSnapshot>? _snapshotSub;

  // Óra-push (A14): a service-izolátumbeli true-time, a change-detect
  // controller, és a legutóbbi snapshot a payload-építéshez.
  TrueTimeManager? _trueTime;
  WatchSyncController? _watchSync;
  RaceSnapshot? _latestSnapshot;

  // A critical warningokat itt lokalizáljuk (widget-fa nélkül, ADR 0015 D4);
  // v1 magyar.
  final AppLocalizations _l10n = lookupAppLocalizations(const Locale('hu'));

  // Dup-init guard: az első init-parancs indítja az engine-t, a továbbiakat
  // (pl. egy ismételt ready-kézfogás után) elnyeljük.
  bool _started = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    developer.log('RaceEngine indult (${starter.name})', name: 'RaceEngine');

    final client = Nmea0183TcpClient(host: engineGatewayHost());
    // Másodlagos, WAL-módú telemetria-kapcsolat (ADR 0017 D6): kész sémát
    // feltételez (a UI-izolátum már migrált), csak a telemetria-táblát írja.
    final db = AppDatabase.secondary();
    final engine = RaceEngine(
      nmeaStream: client,
      telemetryLogger: TelemetryLoggerImpl(db),
    );
    _client = client;
    _db = db;
    _engine = engine;
    _snapshotSub = engine.snapshots.listen(_onSnapshot);

    // Óra-push (A14): a true-time anchor a service-izolátumban fut a valós
    // GNSS-fix forrással, így kijelző-off mellett is van GPS-idő; a controller
    // change-detectel, a transport (e2.2b: log) küld.
    _trueTime = TrueTimeManager(
      gnssClock: geolocatorCurrentUtcFix,
      wallClock: DateTime.now,
    )..start();
    _watchSync = WatchSyncController(
      buildPayload: _buildWatchPayload,
      transport: _logWatchPayload,
    );

    // Ready-kézfogás: jelezzük, hogy fogadjuk a Race initet (A13). A start()
    // csak az init-parancsra fut, így nincs versenyhelyzet a sendDataToTask és
    // a kommunikációs port felállása között.
    FlutterForegroundTask.sendDataToMain(
      jsonEncode(<String, Object>{'type': 'ready'}),
    );
  }

  @override
  void onReceiveData(Object data) {
    if (data is! String) {
      return;
    }
    final map = jsonDecode(data) as Map<String, dynamic>;
    switch (map['type'] as String?) {
      case 'init':
        if (_started) {
          return;
        }
        _started = true;
        final race = raceFromJson(map['race'] as Map<String, dynamic>);
        final engine = _engine;
        if (engine != null) {
          unawaited(engine.start(race));
        }
      case 'start':
        _engine?.applyStartCommand(_atFromMillis(map['at'] as int));
      case 'finish':
        _engine?.applyFinishCommand(_atFromMillis(map['at'] as int));
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Nincs használatban: az engine saját Timer.periodic-ja ketyeg
    // (eventAction: nothing(), ADR 0017 D7).
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    developer.log(
      'RaceEngine leállt (timeout: $isTimeout)',
      name: 'RaceEngine',
    );
    await _snapshotSub?.cancel();
    // Az óra-push leállítása a telemetria-flush ELŐTT: ne épüljön/küldjön
    // payload teardown közben.
    _watchSync?.dispose();
    _trueTime?.dispose();
    // A telemetria záró flush-e az engine.dispose()-ban történik; a DB-t CSAK
    // utána zárjuk, hogy az utolsó batch lemenjen (graceful finish-then-stop).
    await _engine?.dispose();
    await _client?.dispose();
    await _db?.close();
  }

  // Egy engine-snapshotot JSON-stringként továbbít a UI-izolátumnak, és
  // megpörgeti az óra-push change-detectjét (A14).
  void _onSnapshot(RaceSnapshot snapshot) {
    unawaited(
      FlutterForegroundTask.updateService(
        notificationTitle: 'Foretack — verseny aktív',
        notificationText: 'Események: ${snapshot.eventCount}',
      ),
    );
    FlutterForegroundTask.sendDataToMain(jsonEncode(snapshot.toJson()));

    _latestSnapshot = snapshot;
    _watchSync?.onTick();
  }

  // A legutóbbi snapshotból + a service-izolátumbeli true-time-ból építi az
  // óra-payloadot; a warningokat itt értékeli ki és lokalizálja (A14).
  WatchPayload _buildWatchPayload() {
    final snapshot = _latestSnapshot;
    final trueTime =
        _trueTime?.read() ??
        const TrueTimeReading(utc: null, source: TrueTimeSource.none);
    if (snapshot == null) {
      return WatchPayload(timestamp: DateTime.now());
    }
    final warnings = const EvaluateWarnings()(
      connectionStatus: snapshot.connectionStatus,
      boatState: snapshot.boatState,
      windShiftTrend: snapshot.windShiftTrend,
      raceStatus: snapshot.raceStatus,
      isTimeUnsynced: trueTime.source == TrueTimeSource.wallClockUnsynced,
      timeStreamDrift: _timeStreamDrift(trueTime, snapshot.boatState),
    );
    return buildWatchPayload(
      boatState: snapshot.boatState,
      trueTime: trueTime,
      activeWarnings: warnings,
      localizeWarning: (warning) => warningMessage(warning, _l10n),
      now: DateTime.now(),
      windData: snapshot.wind,
      prediction: snapshot.prediction,
    );
  }

  // A trueTime − instrument drift; null, ha bármelyik oldal hiányzik (ADR 0014
  // D2 a provider-határon képezte — itt az engine-oldali ekvivalens).
  Duration? _timeStreamDrift(TrueTimeReading trueTime, BoatState boatState) {
    final utc = trueTime.utc;
    final instrumentUtc = boatState.instrumentTimeUtc;
    if (utc == null || instrumentUtc == null) {
      return null;
    }
    return utc.difference(instrumentUtc);
  }

  // Epoch-millis (UTC) → DateTime a parancs-időbélyegekhez (A13 wire-konvenció).
  DateTime _atFromMillis(int millis) =>
      DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
}

// Ideiglenes (e2.2b) stub transport: a payloadot logolja a natív Data Layer
// helyett. A change-detect miatt csak változásra fut. Az e3 váltja le a valódi
// PhoneWearableBridge-re (MethodChannel → Wearable Data Layer DataItem).
Future<void> _logWatchPayload(WatchPayload payload) async {
  developer.log(
    'SOG=${payload.sogKnots?.toStringAsFixed(1)} '
    'predTWA=${payload.predictedTwaAtMark?.toStringAsFixed(0)} '
    'ETA=${payload.etaSeconds} '
    'gpsTrusted=${payload.isGpsTimeTrusted} '
    'crit=${payload.criticalWarnings.length}',
    name: 'WatchPush',
  );
}
