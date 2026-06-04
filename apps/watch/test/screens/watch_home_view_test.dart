import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:watch/screens/watch_home_view.dart';
import 'package:watch/theme/watch_theme.dart';
import 'package:watch/watch_sync/watch_state_provider.dart';

void main() {
  testWidgets('renders payload values from the provider', (tester) async {
    // Arrange — fake forrás a DIP-seamen át (platform nélkül).
    final payload = WatchPayload(
      timestamp: DateTime.utc(2026, 6, 2, 10, 30),
      sogKnots: 6.4,
      markName: 'Tihany',
    );
    final json = jsonEncode(payload.toJson());

    // Act
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchStateSourceProvider.overrideWithValue(
            () => Stream<String>.value(json),
          ),
        ],
        child: MaterialApp(theme: watchDarkTheme, home: const WatchHomeView()),
      ),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('6.4'), findsOneWidget);
    expect(find.text('Tihany'), findsOneWidget);
  });
}
