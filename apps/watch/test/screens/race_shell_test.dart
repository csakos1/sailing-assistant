import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:watch/rotary/rotary_scroll_provider.dart';
import 'package:watch/screens/race_shell.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/theme/watch_theme.dart';
import 'package:watch/watch_sync/gps_clock_reading.dart';
import 'package:watch/watch_sync/race_ongoing_activity.dart';
import 'package:watch/watch_sync/watch_clock_provider.dart';

void main() {
  final colors = watchDarkTheme.extension<WatchColors>()!;
  final payload = WatchPayload(timestamp: DateTime.utc(2026, 6, 2, 10, 30));

  Widget host({
    required Stream<double> rotary,
    required RaceOngoingActivity ongoing,
  }) => ProviderScope(
    overrides: [
      rotaryScrollSourceProvider.overrideWithValue(() => rotary),
      watchClockProvider.overrideWith(
        (ref) =>
            Stream<GpsClockReading>.value(const GpsClockReading.untrusted()),
      ),
      raceOngoingActivityProvider.overrideWithValue(ongoing),
    ],
    child: MaterialApp(
      theme: watchDarkTheme,
      home: Scaffold(
        body: RaceShell(payload: payload, colors: colors, ambient: false),
      ),
    ),
  );

  testWidgets('starts on the next-mark view and rotates with the bezel', (
    tester,
  ) async {
    // A perem-forrást vezérelt streammel injektáljuk; az órát fix,
    // nem-ketyegő olvasattal, hogy ne maradjon függő Timer.
    final deltas = StreamController<double>.broadcast();
    addTearDown(deltas.close);

    await tester.pumpWidget(
      host(rotary: deltas.stream, ongoing: _SpyOngoingActivity()),
    );
    await tester.pumpAndSettle();

    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    expect(controller.page, 1); // alapnézet: B

    // Egy detent visszafelé → A nézet.
    deltas.add(-1);
    await tester.pumpAndSettle();
    expect(controller.page, 0);

    // Két detent előre → B-nél megáll (clamp).
    deltas
      ..add(1)
      ..add(1);
    await tester.pumpAndSettle();
    expect(controller.page, 1);
  });

  testWidgets('starts the ongoing activity when the display mounts', (
    tester,
  ) async {
    final spy = _SpyOngoingActivity();
    final deltas = StreamController<double>.broadcast();
    addTearDown(deltas.close);

    await tester.pumpWidget(host(rotary: deltas.stream, ongoing: spy));
    await tester.pumpAndSettle();

    expect(spy.startCount, 1);
    expect(spy.stopCount, 0);
  });

  testWidgets('stops the ongoing activity when the display is disposed', (
    tester,
  ) async {
    final spy = _SpyOngoingActivity();
    final deltas = StreamController<double>.broadcast();
    addTearDown(deltas.close);

    await tester.pumpWidget(host(rotary: deltas.stream, ongoing: spy));
    await tester.pumpAndSettle();

    // A fát kicseréljük → a RaceShell unmountol → dispose().
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    expect(spy.stopCount, 1);
  });
}

/// Natív hívás nélküli kém: csak a start/stop hívások számát jegyzi.
final class _SpyOngoingActivity implements RaceOngoingActivity {
  int startCount = 0;
  int stopCount = 0;

  @override
  Future<void> start() async {
    startCount++;
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }
}
