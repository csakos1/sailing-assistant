import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:phone/engine/engine_heartbeat.dart';

/// A háttér-izolátum belépési pontja.
///
/// A `@pragma('vm:entry-point')` kötelező: a plugin külön izolátumban hívja, ahol
/// a tree-shaking egyébként eltávolítaná.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(RaceEngineTaskHandler());
}

/// A 7-bg-b scaffold háttér-feladata.
///
/// Minden event-nél életjelet küld a UI-nak és frissíti az értesítést, így
/// kikapcsolt képernyőn is bizonyítható, hogy az izolátum fut (ADR 0016). A
/// 7-bg-c-ben ezt a valódi NMEA-pipeline + domain-compute váltja le, amely az
/// `onStart`-ban feliratkozott streamtől ketyeg, nem az `onRepeatEvent` timertől.
class RaceEngineTaskHandler extends TaskHandler {
  int _tickCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    developer.log('RaceEngine indult (${starter.name})', name: 'RaceEngine');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _tickCount++;
    final heartbeat = EngineHeartbeat(
      tickCount: _tickCount,
      timestamp: timestamp.toUtc(),
    );
    developer.log('pulzus #$_tickCount', name: 'RaceEngine');

    // A UI-izolátum kikapcsolt képernyőnél pauzál, ezért az értesítés-szöveg a
    // vizuális bizonyíték: a szám a zárolt képernyőn is nő.
    unawaited(
      FlutterForegroundTask.updateService(
        notificationTitle: 'Foretack — verseny aktív',
        notificationText: 'Pulzus #$_tickCount',
      ),
    );
    FlutterForegroundTask.sendDataToMain(heartbeat.toMap());
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    developer.log(
      'RaceEngine leállt (timeout: $isTimeout)',
      name: 'RaceEngine',
    );
  }
}
