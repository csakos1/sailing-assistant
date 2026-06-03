import 'dart:async';
import 'dart:developer' as developer;

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:phone/engine/engine_gateway_host.dart';
import 'package:phone/engine/engine_heartbeat.dart';

/// A háttér-izolátum belépési pontja.
///
/// A `@pragma('vm:entry-point')` kötelező: a plugin külön izolátumban hívja, ahol
/// a tree-shaking egyébként eltávolítaná.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(RaceEngineTaskHandler());
}

/// A háttér-feladat: az `onStart`-ban felépíti és elindítja a [RaceEngine]-t
/// (NMEA TCP + domain-compute), és minden engine-snapshotot életjelként továbbít
/// a UI-izolátumnak (ADR 0017 D1/D7/D9).
///
/// Az engine a saját 1 Hz-es timeréről ketyeg, nem az `onRepeatEvent`-ről
/// (`eventAction: nothing()`). A `tickCount` mező itt a foldolt domain-események
/// számát hordozza — egy snapshot megérkezése bizonyítja, hogy a pipeline +
/// compute kikapcsolt képernyőn is fut.
///
/// **Interim (7-bg-c):** a forrás egy szintetikus [Race] (egyetlen bója), a
/// telemetria no-op. A valódi, izolátumok közti Race-átadás és a WAL-Drift
/// telemetria a 7-bg-d-ben / külön lépésben jön.
class RaceEngineTaskHandler extends TaskHandler {
  Nmea0183TcpClient? _client;
  RaceEngine? _engine;
  StreamSubscription<RaceEngineSnapshot>? _snapshotSub;

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
    await engine.start(_interimRace());
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

  // Egy engine-snapshotot életjelként továbbít a UI-izolátumnak.
  void _onSnapshot(RaceEngineSnapshot snapshot) {
    final heartbeat = EngineHeartbeat(
      tickCount: snapshot.eventCount,
      timestamp: snapshot.tickTime.toUtc(),
    );
    unawaited(
      FlutterForegroundTask.updateService(
        notificationTitle: 'Foretack — verseny aktív',
        notificationText: 'Események: ${snapshot.eventCount}',
      ),
    );
    FlutterForegroundTask.sendDataToMain(heartbeat.toMap());
  }

  // Interim szintetikus pálya a compute-hoz (7-bg-c verifikáció); a valódi
  // Race-átadás 7-bg-d.
  Race _interimRace() {
    return Race.create(
      id: 'interim',
      name: 'Interim',
      marks: const [
        Mark(
          sequence: 1,
          name: 'Bóya 1',
          position: Coordinate(latitude: 46.95, longitude: 18.1),
        ),
      ],
    );
  }
}

// Interim no-op telemetria (7-bg-c): a valódi WAL-Drift logger később.
class _NoopTelemetryLogger implements TelemetryLogger {
  const _NoopTelemetryLogger();

  @override
  Future<void> log(TelemetryRecord record) async {}

  @override
  Future<void> dispose() async {}
}
