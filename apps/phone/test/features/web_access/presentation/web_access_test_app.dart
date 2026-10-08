import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/clock_provider.dart';

import '../web_access_fakes.dart';

/// A kezeloképernyok widget-tesztjeinek kozos kerete (ADR 0051 Addendum 10
/// Z15): 412 px-es telefon-nezet, magyar app, hamis szerver es kulcsok.
Future<void> pumpWebAccessApp(
  WidgetTester tester, {
  required Widget home,
  required FakeWebServer server,
  required FakeKeys keys,
  required MemoryWebAccountStore store,
}) async {
  tester.view
    ..physicalSize = const Size(412, 915)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        webAccountStoreProvider.overrideWithValue(store),
        pendingJoinStoreProvider.overrideWithValue(store),
        webHttpClientProvider.overrideWithValue(server.client),
        webKeyOperationsProvider.overrideWithValue(keys.operations),
        clockProvider.overrideWithValue(() => testNow),
        readDeviceIdentityProvider.overrideWithValue(
          () async =>
              (deviceName: 'Pixel 9 Pro XL', model: 'Google Pixel 9 Pro XL'),
        ),
      ],
      child: MaterialApp(
        theme: foretackTheme,
        locale: const Locale('hu'),
        localizationsDelegates: phoneLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
