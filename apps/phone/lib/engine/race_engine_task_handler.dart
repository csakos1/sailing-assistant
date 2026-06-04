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

/// A háttér-feladat: az `onStart`-ban felépíti és elindítja a [RaceEngine]-t
/// (NMEA TCP + domain-compute), és minden engine-snapshotot JSON-ként továbbít
/// a UI-izolátumnak (ADR 0017 D1/D7/D9 + addendum).
///
/// Az engine a saját 1 Hz-es timeréről ketyeg, nem az `onRepeatEvent`-ről
/// (`eventAction: nothing()`). Minden `RaceSnapshot` `toJson()`-ja a
/// plugin-csatornán JSON-stringként megy át; a UI-oldal `RaceSnapshot.fromJson`-
/// nal fejti vissza.
///
/// **Interim (7-bg-d):** a forrás egy szintetikus [Race] (egyetlen bója), a
/// telemetria no-op. A valódi, izolátumok közti Race-átadás a d4, a WAL-Drift
/// telemetria a d5.
class RaceEngineTaskHandler extends TaskHandler {
  Nmea0183TcpClient? _client;
  RaceEngine? _engine;
  StreamSubscription<RaceSnapshot>? _snapshotSub;

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

  // Interim szintetikus pálya a compute-hoz; a valódi Race-átadás a d4.
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

// Interim no-op telemetria: a valódi WAL-Drift logger a d5-ben.
class _NoopTelemetryLogger implements TelemetryLogger {
  const _NoopTelemetryLogger();

  @override
  Future<void> log(TelemetryRecord record) async {}

  @override
  Future<void> dispose() async {}
}
