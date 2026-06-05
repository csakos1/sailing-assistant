import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch/screens/watch_home_view.dart';
import 'package:watch/theme/watch_theme.dart';
import 'package:watch/watch_sync/watch_state_provider.dart';

void main() {
  Widget host(WatchStateSource source) => ProviderScope(
    overrides: [watchStateSourceProvider.overrideWithValue(source)],
    child: MaterialApp(theme: watchDarkTheme, home: const WatchHomeView()),
  );

  testWidgets('shows a spinner until a payload arrives', (tester) async {
    // Sosem emittáló forrás → a stream loading-ben marad.
    final controller = StreamController<String>();
    addTearDown(controller.close);

    await tester.pumpWidget(host(() => controller.stream));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the no-data message on a stream error', (tester) async {
    await tester.pumpWidget(
      host(() => Stream<String>.error(Exception('boom'))),
    );
    await tester.pump();

    expect(find.text('Nincs adat'), findsOneWidget);
  });
}
