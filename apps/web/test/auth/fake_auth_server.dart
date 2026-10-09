import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/api/archive_api_client.dart';
import 'package:foretack_web/app/api_providers.dart';
import 'package:foretack_web/app/foretack_web_app.dart';
import 'package:foretack_web/app/http_client_provider.dart';
import 'package:foretack_web/auth/auth_api_client.dart';
import 'package:foretack_web/auth/auth_api_client_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:race_archive_api/race_archive_api.dart';

import 'auth_fixtures.dart';

// Egy allithato szerver a bejelentkezes widget-tesztjeihez: a `me`, a
// belepesi keresek, a `poll`, a tartalek belepes es egy ures naplo.

/// A teszt szervere; a mezoi a kovetkezo valaszokat allitjak.
class FakeAuthServer {
  /// A `GET /api/auth/me` valasza; alapbol kijelentkezve.
  http.Response Function() me = () => errorResponse(const NotAuthenticated());

  /// A `poll` allapota.
  LoginRequestState pollState = LoginRequestState.pending;

  /// A `signedIn` allapot fiokja.
  AccountInfo account = const AccountInfo(
    userId: 'user-1',
    name: 'Akos',
    role: UserRole.owner,
  );

  /// Igaz eseten a `poll` halozati hibaval bukik.
  bool isPollFailing = false;

  /// A tartalek belepes valasza.
  http.Response Function() fallback = () =>
      errorResponse(const NotAuthenticated());

  /// Az eddig nyitott belepesi keresek szama.
  int openedRequests = 0;

  /// Az archivum keresei (naplo), a kapu mogott.
  int archiveRequests = 0;

  /// A kijelentkezes valasza; alapbol `204`.
  http.Response Function() logout = () => http.Response('', 204);

  /// Az eddigi kijelentkezesek szama.
  int signOuts = 0;

  /// Igaz eseten az archivum `401`-et ad: a munkamenet lejart.
  bool isArchiveUnauthorized = false;

  /// A tartalek belepesek torzsei.
  final List<String> fallbackBodies = [];

  /// A keres kiszolgalasa.
  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    if (path == mePath) return me();
    if (path == logoutPath) {
      signOuts++;
      return logout();
    }
    if (path == loginRequestsPath) {
      openedRequests++;
      return ticketResponse(openedRequests);
    }
    if (path.endsWith('/poll')) {
      if (isPollFailing) throw http.ClientException('offline');
      return statusResponse(
        pollState,
        account: pollState == LoginRequestState.signedIn ? account : null,
      );
    }
    if (path == fallbackLoginPath) {
      fallbackBodies.add(request.body);
      return fallback();
    }
    if (path == racesPath) {
      archiveRequests++;
      if (isArchiveUnauthorized) return errorResponse(const NotAuthenticated());
      return jsonResponse(encodeRaceSummaries(const []));
    }
    return http.Response('', 404);
  }

  /// A teljes webes app ezzel a szerverrel, 1280 x 1000-es nezetben.
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1280, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final client = MockClient(handle);
    final baseUri = Uri.parse('http://localhost/');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authApiClientProvider.overrideWithValue(
            AuthApiClient(client, baseUri: baseUri),
          ),
          archiveApiClientProvider.overrideWithValue(
            ArchiveApiClient(client, baseUri: baseUri),
          ),
        ],
        child: const ForetackWebApp(),
      ),
    );
    await flush(tester);
  }
}

/// A teljes webes app a valodi API-kliensekkel; csak a HTTP-kliens a
/// teszte. Igy a `401`-figyelo burok is a lancban van.
Future<void> pumpAppOverHttp(WidgetTester tester, FakeAuthServer server) async {
  tester.view
    ..physicalSize = const Size(1280, 1000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        httpClientProvider.overrideWithValue(MockClient(server.handle)),
      ],
      child: const ForetackWebApp(),
    ),
  );
  await flush(tester);
}

/// A fuggo valaszok es a kepkockak feldolgozasa ido mulasa nelkul.
Future<void> flush(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

/// Az ido [duration]-nyi mulasa, utana a valaszok feldolgozasa.
Future<void> advance(WidgetTester tester, Duration duration) async {
  await tester.pump(duration);
  await flush(tester);
}
