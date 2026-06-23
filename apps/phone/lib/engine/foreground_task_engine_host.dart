import 'dart:async';
import 'dart:convert';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:phone/engine/race_engine_host.dart';
import 'package:phone/engine/race_engine_task_handler.dart';

/// A [RaceEngineHost] foreground-service alapú implementációja
/// (`flutter_foreground_task`).
///
/// A háttér-izolátumtól érkező JSON-stringeket `RaceSnapshot`-tá fejti és egy
/// broadcast streamre teszi. Az életciklus a foreground service-t indítja/
/// állítja le; a snapshotok a UI read-only tükrét táplálják. A Race-init a
/// task ready-jelére megy ki (A13 kézfogás); a Start/Finish parancsok a
/// `sendDataToTask`-on.
class ForegroundTaskEngineHost implements RaceEngineHost {
  final StreamController<RaceSnapshot> _controller =
      StreamController<RaceSnapshot>.broadcast();

  // A legutóbbi start()-tal átadott Race; a task ready-jelére ezt küldjük
  // init-ként (A13). null, amíg nem indult session.
  Race? _pendingRace;

  // A legutóbbi start()-tal átadott polár (ADR 0028 Add. 3); az init-üzenet
  // viszi a háttérbe. null → a háttér null-polárral fut (cél-sebesség null).
  Polar? _pendingPolar;

  @override
  Stream<RaceSnapshot> get snapshots => _controller.stream;

  @override
  Future<String?> start(Race race, {Polar? polar}) async {
    _pendingRace = race;
    _pendingPolar = polar;
    await _requestNotificationPermission();
    _initService();

    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    // Ha maradt árva service egy korábbi app-processből (a service túléli a
    // taszk-eltávolítást), előbb teljesen leállítjuk. A restartService
    // cold-launch után nem mindig köti újra a main↔task csatornát, így a
    // ready-kézfogás (A13) elveszhet, az engine nem kapja meg az initet, és
    // nem indul NMEA-kapcsolat (az eventCount 0 marad). A friss startService
    // a most regisztrált callback-kel és tiszta isolate-tal indul.
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    // ADR 0017 A14: a service-izolátumbeli GNSS true-time-hoz FGS `location`
    // típus kell; csak akkor vesszük fel, ha a futásidejű helyengedély megvan,
    // különben az Android 14+ a service indítását SecurityExceptionnel dobná.
    // Engedély nélkül connectedDevice-only → az engine fut, csak a GPS-idő
    // marad jelöletlen (graceful degradáció).
    final serviceTypes = <ForegroundServiceTypes>[
      ForegroundServiceTypes.connectedDevice,
    ];
    if (await _hasLocationPermission()) {
      serviceTypes.add(ForegroundServiceTypes.location);
    }
    final result = await FlutterForegroundTask.startService(
      serviceId: 256,
      serviceTypes: serviceTypes,
      notificationTitle: 'Foretack — verseny aktív',
      notificationText: 'A háttér-engine indul…',
      callback: startCallback,
    );

    // A ServiceRequestFailure üzenetét adjuk vissza (a UI a státuszsorba teszi,
    // A13); siker → null.
    if (result is ServiceRequestFailure) {
      return result.error.toString();
    }
    return null;
  }

  @override
  void sendStartCommand(DateTime at) {
    FlutterForegroundTask.sendDataToTask(
      jsonEncode(<String, Object>{
        'type': 'start',
        'at': at.toUtc().millisecondsSinceEpoch,
      }),
    );
  }

  @override
  void sendFinishCommand(DateTime at) {
    FlutterForegroundTask.sendDataToTask(
      jsonEncode(<String, Object>{
        'type': 'finish',
        'at': at.toUtc().millisecondsSinceEpoch,
      }),
    );
  }

  @override
  void sendRoundMarkCommand() {
    FlutterForegroundTask.sendDataToTask(
      jsonEncode(<String, Object>{'type': 'roundMark'}),
    );
  }

  @override
  Future<void> stop() async {
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    await FlutterForegroundTask.stopService();
  }

  @override
  Future<void> dispose() async {
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    await _controller.close();
  }

  // A task→UI üzenetek: a ready-jelre kiküldjük a Race initet, egyébként a
  // snapshotot fejtjük vissza (a snapshot-mapnek nincs `type` kulcsa, A13).
  void _onReceiveTaskData(Object data) {
    if (data is! String) {
      return;
    }
    final map = jsonDecode(data) as Map<String, dynamic>;
    if (map['type'] == 'ready') {
      final race = _pendingRace;
      if (race != null) {
        final polar = _pendingPolar;
        FlutterForegroundTask.sendDataToTask(
          jsonEncode(<String, Object?>{
            'type': 'init',
            'race': raceToJson(race),
            'polar': polar == null ? null : polarToJson(polar),
          }),
        );
      }
      return;
    }
    _controller.add(RaceSnapshot.fromJson(map));
  }

  Future<void> _requestNotificationPermission() async {
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  // Futásidejű helyengedély (whileInUse elég az FGS-hez); a dialógus a UI-
  // izolátumból kérhető, mert a race-indításkor az Activity előtérben van.
  Future<bool> _hasLocationPermission() async {
    final initial = await Geolocator.checkPermission();
    final permission = initial == LocationPermission.denied
        ? await Geolocator.requestPermission()
        : initial;
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  void _initService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foretack_race',
        channelName: 'Verseny aktív',
        channelDescription:
            'Akkor jelenik meg, amikor a verseny-engine a háttérben fut.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWifiLock: true,
      ),
    );
  }
}
