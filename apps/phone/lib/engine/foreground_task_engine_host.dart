import 'dart:async';
import 'dart:convert';

import 'package:data/data.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:phone/engine/race_engine_host.dart';
import 'package:phone/engine/race_engine_task_handler.dart';

/// A [RaceEngineHost] foreground-service alapú implementációja
/// (`flutter_foreground_task`).
///
/// A háttér-izolátumtól érkező JSON-stringeket `RaceSnapshot`-tá fejti és egy
/// broadcast streamre teszi. Az életciklus a foreground service-t indítja/
/// állítja le; a snapshotok a UI read-only tükrét táplálják.
class ForegroundTaskEngineHost implements RaceEngineHost {
  final StreamController<RaceSnapshot> _controller =
      StreamController<RaceSnapshot>.broadcast();

  @override
  Stream<RaceSnapshot> get snapshots => _controller.stream;

  @override
  Future<void> start() async {
    await _requestNotificationPermission();
    _initService();

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
    if (data is String) {
      final map = jsonDecode(data) as Map<String, dynamic>;
      _controller.add(RaceSnapshot.fromJson(map));
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
