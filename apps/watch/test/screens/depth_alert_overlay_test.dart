import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch/screens/depth_alert_overlay.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/theme/watch_theme.dart';

void main() {
  Future<void> pumpOverlay(
    WidgetTester tester, {
    required WatchColors colors,
    required bool ambient,
  }) => tester.pumpWidget(
    MaterialApp(
      home: DepthAlertOverlay(
        depthMeters: 2.1,
        colors: colors,
        ambient: ambient,
        onDismiss: () {},
      ),
    ),
  );

  testWidgets('the alert text on the red field uses onCritical', (
    tester,
  ) async {
    await pumpOverlay(tester, colors: watchNightColors, ambient: false);

    final depth = tester.widget<Text>(find.text('2.1 m'));

    expect(depth.style?.color, watchNightColors.onCritical);
    // A lenyeg a kulonbseg: a narancs szovegszin ezen a hatteren 1,10:1.
    expect(depth.style?.color, isNot(watchNightColors.text));
  });

  testWidgets('the day token set still writes light on the red field', (
    tester,
  ) async {
    await pumpOverlay(tester, colors: watchDayColors, ambient: false);

    final depth = tester.widget<Text>(find.text('2.1 m'));

    expect(depth.style?.color, const Color(0xFFE9F1F7));
  });

  testWidgets('ambient keeps red text and drops the dismiss button', (
    tester,
  ) async {
    await pumpOverlay(tester, colors: watchNightColors, ambient: true);

    final depth = tester.widget<Text>(find.text('2.1 m'));

    expect(depth.style?.color, watchNightColors.critical);
    expect(find.byType(TextButton), findsNothing);
  });
}
