import 'dart:async';
import 'dart:convert';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
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

  @override
  Stream<RaceSnapshot> get snapshots => _controller.stream;

  @override
  Future<String?> start(Race race) async {
    _pendingRace = race;
    await _requestNotificationPermission();
    _initService();

    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    final ServiceRequestResult result;
    if (await FlutterForegroundTask.isRunningService) {
      result = await FlutterForegroundTask.restartService();
    } else {
      result = await FlutterForegroundTask.startService(
        serviceId: 256,
        serviceTypes: const [ForegroundServiceTypes.connectedDevice],
        notificationTitle: 'Foretack — verseny aktív',
        notificationText: 'A háttér-engine indul…',
        callback: startCallback,
      );
    }

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
        FlutterForegroundTask.sendDataToTask(
          jsonEncode(<String, Object>{
            'type': 'init',
            'race': raceToJson(race),
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
