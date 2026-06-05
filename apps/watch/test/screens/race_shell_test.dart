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
import 'package:watch/watch_sync/watch_clock_provider.dart';

void main() {
  final colors = watchDarkTheme.extension<WatchColors>()!;
  final payload = WatchPayload(timestamp: DateTime.utc(2026, 6, 2, 10, 30));

  testWidgets('starts on the next-mark view and rotates with the bezel', (
    tester,
  ) async {
    // A perem-forrást vezérelt streammel injektáljuk; az órát fix,
    // nem-ketyegő olvasattal, hogy ne maradjon függő Timer.
    final deltas = StreamController<double>.broadcast();
    addTearDown(deltas.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rotaryScrollSourceProvider.overrideWithValue(() => deltas.stream),
          watchClockProvider.overrideWith(
            (ref) => Stream<GpsClockReading>.value(
              const GpsClockReading.untrusted(),
            ),
          ),
        ],
        child: MaterialApp(
          theme: watchDarkTheme,
          home: Scaffold(
            body: RaceShell(payload: payload, colors: colors, ambient: false),
          ),
        ),
      ),
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
}
