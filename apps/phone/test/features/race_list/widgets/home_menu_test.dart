import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_list/widgets/home_menu.dart';

import '../../web_access/presentation/web_access_test_app.dart';
import '../../web_access/web_access_fakes.dart';

void main() {
  late FakeWebServer server;
  late List<HomeMenuItem> selected;

  setUp(() {
    server = FakeWebServer();
    selected = [];
  });

  // Fiok nelkuli telefon: csak a debug-csoport adhat menut.
  Future<void> pumpMenu(WidgetTester tester, {required bool showsDebug}) =>
      pumpWebAccessApp(
        tester,
        server: server,
        keys: FakeKeys(),
        store: MemoryWebAccountStore(),
        home: Scaffold(
          appBar: AppBar(
            actions: [
              HomeMenu(onSelected: selected.add, showsDebugItems: showsDebug),
            ],
          ),
        ),
      );

  testWidgets('shows the debug group without an account in debug', (
    tester,
  ) async {
    // ARRANGE
    await pumpMenu(tester, showsDebug: true);

    // ACT
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // ASSERT — a webes csoport fiok nelkul rejtve marad (ADR 0056 D7).
    expect(find.text('FEJLESZTÉS'), findsOneWidget);
    expect(find.text('Nyers NMEA'), findsOneWidget);
    expect(find.text('Engine debug'), findsOneWidget);
    expect(find.text('WEBES HOZZÁFÉRÉS'), findsNothing);
  });

  testWidgets('reports the picked debug row', (tester) async {
    // ARRANGE
    await pumpMenu(tester, showsDebug: true);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // ACT
    await tester.tap(find.text('Engine debug'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(selected, [HomeMenuItem.engineDebug]);
  });

  testWidgets('is hidden without an account in a release build', (
    tester,
  ) async {
    // ACT
    await pumpMenu(tester, showsDebug: false);

    // ASSERT
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });
}
