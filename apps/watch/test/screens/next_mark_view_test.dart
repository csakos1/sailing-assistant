import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:watch/screens/next_mark_view.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/theme/watch_theme.dart';
import 'package:watch/widgets/direction_arrow.dart';

void main() {
  final colors = watchDarkTheme.extension<WatchColors>()!;
  final payload = WatchPayload(
    timestamp: DateTime.utc(2026, 6, 2, 10, 30),
    predictedTwaAtMark: -38, // port → bal nyíl (befelé)
    courseCorrection: 12, // jobbra → jobb nyíl (kifelé)
    etaSeconds: 452,
    distanceMeters: 450,
    markName: 'Tihany',
  );

  Widget host({required bool ambient}) => MaterialApp(
    theme: watchDarkTheme,
    home: Scaffold(
      body: NextMarkView(payload: payload, colors: colors, ambient: ambient),
    ),
  );

  WatchPayload payloadWith({
    String? twdQuality,
    String? shiftConfidence,
    double? forecastBandDegrees,
  }) => WatchPayload(
    timestamp: DateTime.utc(2026, 6, 2, 10, 30),
    predictedTwaAtMark: -38,
    courseCorrection: 12,
    etaSeconds: 452,
    distanceMeters: 450,
    markName: 'Tihany',
    twdQuality: twdQuality,
    shiftConfidence: shiftConfidence,
    forecastBandDegrees: forecastBandDegrees,
  );

  Widget hostFor(WatchPayload p, {required bool ambient}) => MaterialApp(
    theme: watchDarkTheme,
    home: Scaffold(
      body: NextMarkView(payload: p, colors: colors, ambient: ambient),
    ),
  );

  double? heroOpacity(WidgetTester tester) {
    final f = find.ancestor(
      of: find.byType(FittedBox),
      matching: find.byType(Opacity),
    );
    return f.evaluate().isEmpty ? null : tester.widget<Opacity>(f).opacity;
  }

  testWidgets('held dims the hero and shows the held marker', (tester) async {
    await tester.pumpWidget(
      hostFor(
        payloadWith(twdQuality: 'held', shiftConfidence: 'medium'),
        ambient: false,
      ),
    );

    expect(heroOpacity(tester), 0.6);
    expect(find.text('tartott'), findsOneWidget);
  });

  testWidgets('live keeps the hero un-dimmed, no held marker', (tester) async {
    await tester.pumpWidget(
      hostFor(
        payloadWith(twdQuality: 'live', shiftConfidence: 'high'),
        ambient: false,
      ),
    );

    expect(heroOpacity(tester), isNull); // nincs Opacity-wrap
    expect(find.text('tartott'), findsNothing);
  });

  testWidgets('band renders the ±degrees label', (tester) async {
    await tester.pumpWidget(
      hostFor(
        payloadWith(shiftConfidence: 'high', forecastBandDegrees: 7),
        ambient: false,
      ),
    );

    expect(find.text('±7°'), findsOneWidget);
  });

  testWidgets('ambient keeps the band, hides held marker + dimming', (
    tester,
  ) async {
    await tester.pumpWidget(
      hostFor(
        payloadWith(
          twdQuality: 'held',
          shiftConfidence: 'high',
          forecastBandDegrees: 5,
        ),
        ambient: true,
      ),
    );

    expect(heroOpacity(tester), isNull); // ambientben nincs TWD-opacitás
    expect(find.text('tartott'), findsNothing); // ambientben elmarad
    // A ±° sáv ambientben is megmarad (ADR 0023 D8); az ívet a RaceShell adja.
    expect(find.text('±5°'), findsOneWidget);
  });

  testWidgets('renders title, predicted TWA, correction value and ETA', (
    tester,
  ) async {
    await tester.pumpWidget(host(ambient: false));

    expect(find.text('Tihany · 450 m'), findsOneWidget);
    expect(find.text('38°'), findsOneWidget); // pred-TWA hero magnitude
    expect(find.text('Korr.'), findsOneWidget);
    expect(find.text('12°'), findsOneWidget); // korrekció magnitude
    expect(find.text('07:32'), findsOneWidget); // ETA
    // pred-TWA nyíl + korrekció nyíl.
    expect(find.byType(DirectionArrow), findsNWidgets(2));
  });

  testWidgets('shows the muted hero with a neutral arrow in ambient mode', (
    tester,
  ) async {
    await tester.pumpWidget(host(ambient: true));

    expect(find.text('38°'), findsOneWidget);
    expect(find.text('Tihany · 450 m'), findsNothing); // cím rejtve
    expect(find.text('07:32'), findsNothing); // ETA rejtve
    expect(find.text('12°'), findsNothing); // korrekció rejtve
    expect(
      find.byType(DirectionArrow),
      findsOneWidget,
    ); // a hero tompított nyila
  });
}
