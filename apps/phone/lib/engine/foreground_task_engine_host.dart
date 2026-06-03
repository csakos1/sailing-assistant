import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:phone/engine/engine_heartbeat.dart';
import 'package:phone/engine/race_engine_host.dart';
import 'package:phone/engine/race_engine_task_handler.dart';

/// A [RaceEngineHost] foreground-service alapú implementációja
/// (`flutter_foreground_task`).
///
/// A háttér-izolátumtól érkező Map-eket [EngineHeartbeat]-té fejti és egy
/// broadcast streamre teszi. A 7-bg-b-ben csak az életciklust és az
/// életjel-továbbítást valósítja meg; a valódi pipeline a 7-bg-c-ben jön.
class ForegroundTaskEngineHost implements RaceEngineHost {
  final StreamController<EngineHeartbeat> _controller =
      StreamController<EngineHeartbeat>.broadcast();

  @override
  Stream<EngineHeartbeat> get heartbeats => _controller.stream;

  @override
  Future<void> start() async {
    await _requestNotificationPermission();
    _initService();

    // A start/stop párban hívandó (a debug-UI ezt betartja); a 7-bg-c valódi
    // lifecycle-je kezeli majd a kettőzés elleni védelmet.
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        serviceId: 256,
        serviceTypes: const [ForegroundServiceTypes.connectedDevice],
        notificationTitle: 'Foretack — verseny aktív',
        notificationText: 'A háttér-engine indul…',
        callback: startCallback,
      );
    }
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

  void _onReceiveTaskData(Object data) {
    if (data is Map) {
      _controller.add(EngineHeartbeat.fromMap(Map<String, dynamic>.from(data)));
    }
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
