import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:phone/engine/engine_gateway_host.dart';

/// A háttér-izolátum belépési pontja.
///
/// A `@pragma('vm:entry-point')` kötelező: a plugin külön izolátumban hívja, ahol
/// a tree-shaking egyébként eltávolítaná.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(RaceEngineTaskHandler());
}

/// A háttér-feladat: az `onStart`-ban felépíti a [RaceEngine]-t (NMEA TCP +
/// domain-compute), de NEM indítja — előbb egy `{type:'ready'}` jelet küld a
/// hostnak (ready-kézfogás, ADR 0017 A13). A host erre küldi a teljes [Race]
/// initet (`{type:'init', race:…}`), amire az engine elindul; futás közben a
/// `{type:'start'|'finish', at}` parancsokat a saját `_race`-én alkalmazza.
///
/// Minden engine-snapshot `toJson()`-ja a plugin-csatornán JSON-stringként megy
/// a UI-izolátumnak; az engine a saját 1 Hz-es timeréről ketyeg, nem az
/// `onRepeatEvent`-ről (`eventAction: nothing()`). A telemetria a d5-ig no-op.
class RaceEngineTaskHandler extends TaskHandler {
  Nmea0183TcpClient? _client;
  RaceEngine? _engine;
  StreamSubscription<RaceSnapshot>? _snapshotSub;

  // Dup-init guard: az első init-parancs indítja az engine-t, a továbbiakat
  // (pl. egy ismételt ready-kézfogás után) elnyeljük.
  bool _started = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    developer.log('RaceEngine indult (${starter.name})', name: 'RaceEngine');

    final client = Nmea0183TcpClient(host: engineGatewayHost());
    final engine = RaceEngine(
      nmeaStream: client,
      telemetryLogger: const _NoopTelemetryLogger(),
    );
    _client = client;
    _engine = engine;
    _snapshotSub = engine.snapshots.listen(_onSnapshot);

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
    await _engine?.dispose();
    await _client?.dispose();
  }

  // Egy engine-snapshotot JSON-stringként továbbít a UI-izolátumnak.
  void _onSnapshot(RaceSnapshot snapshot) {
    unawaited(
      FlutterForegroundTask.updateService(
        notificationTitle: 'Foretack — verseny aktív',
        notificationText: 'Események: ${snapshot.eventCount}',
      ),
    );
    FlutterForegroundTask.sendDataToMain(jsonEncode(snapshot.toJson()));
  }

  // Epoch-millis (UTC) → DateTime a parancs-időbélyegekhez (A13 wire-konvenció).
  DateTime _atFromMillis(int millis) =>
      DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
}

// Interim no-op telemetria: a valódi WAL-Drift logger a d5-ben.
class _NoopTelemetryLogger implements TelemetryLogger {
  const _NoopTelemetryLogger();

  @override
  Future<void> log(TelemetryRecord record) async {}

  @override
  Future<void> dispose() async {}
}
