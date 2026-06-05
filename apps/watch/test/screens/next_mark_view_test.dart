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

  testWidgets('shows only the muted hero in ambient mode', (tester) async {
    await tester.pumpWidget(host(ambient: true));

    expect(find.text('38°'), findsOneWidget);
    expect(find.text('Tihany · 450 m'), findsNothing); // cím rejtve
    expect(find.text('07:32'), findsNothing); // ETA rejtve
    expect(find.text('12°'), findsNothing); // korrekció rejtve
    expect(find.byType(DirectionArrow), findsNothing); // accent nélkül
  });
}
