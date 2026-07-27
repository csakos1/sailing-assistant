import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch/main.dart';
import 'package:watch/theme/night_mode_provider.dart';
import 'package:watch/theme/watch_theme.dart';
import 'package:watch/watch_sync/watch_state_provider.dart';

void main() {
  late StreamController<String> controller;

  setUp(() => controller = StreamController<String>());
  tearDown(() => controller.close());

  Widget host(DateTime now) => ProviderScope(
    overrides: [
      utcClockProvider.overrideWithValue(() => now),
      watchStateSourceProvider.overrideWithValue(() => controller.stream),
    ],
    child: const WatchApp(),
  );

  ThemeData? themeOf(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).theme;

  testWidgets('picks the night theme after sunset', (tester) async {
    await tester.pumpWidget(host(DateTime.utc(2026, 6, 21, 20)));

    expect(themeOf(tester), same(watchNightTheme));
  });

  testWidgets('picks the dark theme at midday', (tester) async {
    await tester.pumpWidget(host(DateTime.utc(2026, 6, 21, 10)));

    expect(themeOf(tester), same(watchDarkTheme));
  });
}
