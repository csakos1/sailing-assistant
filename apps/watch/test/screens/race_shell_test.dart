import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:watch/rotary/rotary_scroll_provider.dart';
import 'package:watch/screens/depth_alert_overlay.dart';
import 'package:watch/screens/race_shell.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/theme/watch_theme.dart';
import 'package:watch/watch_sync/depth_alert_vibrator.dart';
import 'package:watch/watch_sync/gps_clock_reading.dart';
import 'package:watch/watch_sync/race_ongoing_activity.dart';
import 'package:watch/watch_sync/watch_clock_provider.dart';
import 'package:watch/widgets/confidence_arc.dart';

void main() {
  final colors = watchDarkTheme.extension<WatchColors>()!;
  final payload = WatchPayload(timestamp: DateTime.utc(2026, 6, 2, 10, 30));

  // Predikció-konfidenciát hordozó payload az ív-tesztekhez (B-lap).
  final arcPayload = WatchPayload(
    timestamp: DateTime.utc(2026, 6, 2, 10, 30),
    predictedTwaAtMark: -38,
    courseCorrection: 12,
    etaSeconds: 452,
    distanceMeters: 450,
    markName: 'Tihany',
    shiftConfidence: 'high',
  );

  Widget host({
    required Stream<double> rotary,
    required RaceOngoingActivity ongoing,
    WatchPayload? payloadOverride,
    bool ambient = false,
    DepthAlertVibrator? vibrator,
  }) => ProviderScope(
    overrides: [
      depthAlertVibratorProvider.overrideWithValue(vibrator ?? _noopBuzz),
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
        body: RaceShell(
          payload: payloadOverride ?? payload,
          colors: colors,
          ambient: ambient,
        ),
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

    // A perem-irány megfordítva: negatív detent a C-lap felé lapoz.
    deltas.add(-1);
    await tester.pumpAndSettle();
    expect(controller.page, 2);

    // A C-lapnál megáll (clamp a tetején): további negatív detent nem lép.
    deltas.add(-1);
    await tester.pumpAndSettle();
    expect(controller.page, 2);

    // Pozitív detent az A-lap felé lapoz (C → B → A).
    deltas.add(1);
    await tester.pumpAndSettle();
    expect(controller.page, 1);
    deltas.add(1);
    await tester.pumpAndSettle();
    expect(controller.page, 0);

    // Az A-lapnál megáll (clamp az alján): további pozitív detent nem lép.
    deltas.add(1);
    await tester.pumpAndSettle();
    expect(controller.page, 0);
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

  testWidgets('a konfidencia-ív a B-lapon látszik (jobb perem)', (
    tester,
  ) async {
    final deltas = StreamController<double>.broadcast();
    addTearDown(deltas.close);

    await tester.pumpWidget(
      host(
        rotary: deltas.stream,
        ongoing: _SpyOngoingActivity(),
        payloadOverride: arcPayload,
      ),
    );
    await tester.pumpAndSettle();

    final arc = tester.widget<ConfidenceArc>(find.byType(ConfidenceArc));
    expect(arc.color, colors.signal); // high → teal
    expect(arc.fraction, 1);
    expect(arc.ambient, isFalse);
  });

  testWidgets('a konfidencia-ív az A-lapon nem látszik', (tester) async {
    final deltas = StreamController<double>.broadcast();
    addTearDown(deltas.close);

    await tester.pumpWidget(
      host(
        rotary: deltas.stream,
        ongoing: _SpyOngoingActivity(),
        payloadOverride: arcPayload,
      ),
    );
    await tester.pumpAndSettle();

    // Megfordított irány: pozitív detent vissza → A (sebesség) nézet.
    deltas.add(1);
    await tester.pumpAndSettle();

    expect(find.byType(ConfidenceArc), findsNothing);
  });

  testWidgets('a konfidencia-ív ambientben is megmarad a B-lapon', (
    tester,
  ) async {
    final deltas = StreamController<double>.broadcast();
    addTearDown(deltas.close);

    await tester.pumpWidget(
      host(
        rotary: deltas.stream,
        ongoing: _SpyOngoingActivity(),
        payloadOverride: arcPayload,
        ambient: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<ConfidenceArc>(find.byType(ConfidenceArc)).ambient,
      isTrue,
    );
  });

  testWidgets('predikció-konfidencia nélkül nincs ív', (tester) async {
    final deltas = StreamController<double>.broadcast();
    addTearDown(deltas.close);

    await tester.pumpWidget(
      host(rotary: deltas.stream, ongoing: _SpyOngoingActivity()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ConfidenceArc), findsNothing);
  });

  testWidgets('high-ra való felfutó élén egyszer buzzol (debounce)', (
    tester,
  ) async {
    // ARRANGE — a HapticFeedback platform-hívásait rögzítjük (a heavyImpact
    // a SystemChannels.platform 'HapticFeedback.vibrate' metódusára fordul).
    var buzzCount = 0;
    final messenger = tester.binding.defaultBinaryMessenger
      ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') buzzCount++;
        return null;
      });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final deltas = StreamController<double>.broadcast();
    addTearDown(deltas.close);

    WatchPayload withConfidence(String? c) => WatchPayload(
      timestamp: DateTime.utc(2026, 6, 2, 10, 30),
      shiftConfidence: c,
    );

    Future<void> pumpConfidence(String? c) async {
      await tester.pumpWidget(
        host(
          rotary: deltas.stream,
          ongoing: _SpyOngoingActivity(),
          payloadOverride: withConfidence(c),
        ),
      );
      await tester.pumpAndSettle();
    }

    // ACT/ASSERT — medium kezdés: nincs felfutó él, nincs buzz.
    await pumpConfidence('medium');
    expect(buzzCount, 0);

    // medium → high: egy buzz.
    await pumpConfidence('high');
    expect(buzzCount, 1);

    // high → high: nincs újabb buzz (a debounce maga az él-detektálás).
    await pumpConfidence('high');
    expect(buzzCount, 1);

    // high → medium → high: a vissza-belépés újra buzzol.
    await pumpConfidence('medium');
    await pumpConfidence('high');
    expect(buzzCount, 2);
  });

  testWidgets('sekély víz → teljes-képernyős overlay a mélységgel', (
    tester,
  ) async {
    final deltas = StreamController<double>.broadcast();
    addTearDown(deltas.close);

    await tester.pumpWidget(
      host(
        rotary: deltas.stream,
        ongoing: _SpyOngoingActivity(),
        payloadOverride: _depthPayload(meters: 2.3, counter: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DepthAlertOverlay), findsOneWidget);
    expect(find.text('2.3 m'), findsOneWidget);
    expect(find.text('Bezár'), findsOneWidget);
  });

  testWidgets('riasztás nélkül nincs overlay', (tester) async {
    final deltas = StreamController<double>.broadcast();
    addTearDown(deltas.close);

    await tester.pumpWidget(
      host(rotary: deltas.stream, ongoing: _SpyOngoingActivity()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DepthAlertOverlay), findsNothing);
  });

  testWidgets('ambientben nincs bezárás gomb', (tester) async {
    // OLED burn-in + energia: ambientben nincs nagy piros mező, és az
    // érintés sem megbízható, ezért gomb sincs.
    final deltas = StreamController<double>.broadcast();
    addTearDown(deltas.close);

    await tester.pumpWidget(
      host(
        rotary: deltas.stream,
        ongoing: _SpyOngoingActivity(),
        payloadOverride: _depthPayload(meters: 2.3, counter: 1),
        ambient: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DepthAlertOverlay), findsOneWidget);
    expect(find.text('Bezár'), findsNothing);
  });

  testWidgets('a bezárás elrejti, az új mélypont visszahozza', (tester) async {
    final deltas = StreamController<double>.broadcast();
    addTearDown(deltas.close);

    await tester.pumpWidget(
      host(
        rotary: deltas.stream,
        ongoing: _SpyOngoingActivity(),
        payloadOverride: _depthPayload(meters: 2.3, counter: 1),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bezár'));
    await tester.pumpAndSettle();
    expect(find.byType(DepthAlertOverlay), findsNothing);

    // Ugyanaz a számláló, sekélyebb víz: a bezárás áll (nem nyaggat).
    await tester.pumpWidget(
      host(
        rotary: deltas.stream,
        ongoing: _SpyOngoingActivity(),
        payloadOverride: _depthPayload(meters: 2.2, counter: 1),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DepthAlertOverlay), findsNothing);

    // Új mélypont → nő a számláló → a ratchet visszahozza a riasztást.
    await tester.pumpWidget(
      host(
        rotary: deltas.stream,
        ongoing: _SpyOngoingActivity(),
        payloadOverride: _depthPayload(meters: 2.1, counter: 2),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DepthAlertOverlay), findsOneWidget);
  });

  testWidgets('a számláló változó élén rezeg, egyszer', (tester) async {
    final spy = _SpyDepthAlertVibrator();
    final deltas = StreamController<double>.broadcast();
    addTearDown(deltas.close);

    Future<void> pumpDepth({required double? meters, required int counter}) {
      return tester
          .pumpWidget(
            host(
              rotary: deltas.stream,
              ongoing: _SpyOngoingActivity(),
              payloadOverride: _depthPayload(meters: meters, counter: counter),
              vibrator: spy.buzz,
            ),
          )
          .then((_) => tester.pumpAndSettle());
    }

    // Az induló payload nem rezeg: a didUpdateWidget még nem futott.
    await pumpDepth(meters: 2.4, counter: 1);
    expect(spy.buzzCount, 0);

    // Új mélypont → változik a számláló → egy rezgés.
    await pumpDepth(meters: 2.3, counter: 2);
    expect(spy.buzzCount, 1);

    // Csak a mélység frissül, a számláló nem → nincs újabb rezgés.
    await pumpDepth(meters: 2.2, counter: 2);
    expect(spy.buzzCount, 1);

    // Az epizód vége: a számláló-változás önmagában nem rezeg.
    await pumpDepth(meters: null, counter: 3);
    expect(spy.buzzCount, 1);
  });

  testWidgets('a riasztás alatt a perem nem lapoz', (tester) async {
    final deltas = StreamController<double>.broadcast();
    addTearDown(deltas.close);

    await tester.pumpWidget(
      host(
        rotary: deltas.stream,
        ongoing: _SpyOngoingActivity(),
        payloadOverride: _depthPayload(meters: 2.3, counter: 1),
      ),
    );
    await tester.pumpAndSettle();

    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    expect(controller.page, 1);

    deltas.add(-1);
    await tester.pumpAndSettle();

    expect(controller.page, 1);
  });
}

// Sekély-víz riasztást hordozó payload a mélység-tesztekhez.
WatchPayload _depthPayload({required double? meters, required int counter}) =>
    WatchPayload(
      timestamp: DateTime.utc(2026, 6, 2, 10, 30),
      depthAlertMeters: meters,
      depthBuzzCounter: counter,
    );

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

/// Natív hívás nélküli kém: csak a rezgések számát jegyzi. A `buzz`
/// tear-offja adja a `DepthAlertVibrator` függvény-varratot.
final class _SpyDepthAlertVibrator {
  int buzzCount = 0;

  Future<void> buzz() async {
    buzzCount++;
  }
}

// Néma alapértelmezés a mélységet nem vizsgáló tesztekhez.
Future<void> _noopBuzz() => Future<void>.value();
