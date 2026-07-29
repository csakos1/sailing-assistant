import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_list/widgets/list_action_bar.dart';
import 'package:phone/l10n/app_localizations.dart';

void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    required VoidCallback onNewRace,
    VoidCallback? onFinished,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        locale: const Locale('hu'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              const Spacer(),
              ListActionBar(onNewRace: onNewRace, onFinished: onFinished),
            ],
          ),
        ),
      ),
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ListActionBar)))!;

  testWidgets('disables the finished half without a callback', (tester) async {
    // ARRANGE & ACT
    await pumpBar(tester, onNewRace: () {});
    final l10n = l10nOf(tester);

    // ASSERT - a gomb ott van, csak nem kattinthato.
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, l10n.listFinishedRacesTitle),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('enables the finished half with a callback', (tester) async {
    // ARRANGE
    var taps = 0;
    await pumpBar(tester, onNewRace: () {}, onFinished: () => taps++);
    final l10n = l10nOf(tester);

    // ACT
    await tester.tap(
      find.widgetWithText(TextButton, l10n.listFinishedRacesTitle),
    );
    await tester.pump();

    // ASSERT
    expect(taps, 1);
  });

  testWidgets('reports a tap on the new race half', (tester) async {
    // ARRANGE
    var taps = 0;
    await pumpBar(tester, onNewRace: () => taps++);
    final l10n = l10nOf(tester);

    // ACT
    await tester.tap(find.widgetWithText(FilledButton, l10n.listAddRace));
    await tester.pump();

    // ASSERT
    expect(taps, 1);
  });

  testWidgets('splits the bar into two halves of equal width', (tester) async {
    // ARRANGE & ACT
    await pumpBar(tester, onNewRace: () {}, onFinished: () {});
    final l10n = l10nOf(tester);

    // ASSERT - a felezes akkor is all, ha a ket felirat kulonbozo hosszu.
    final left = tester.getSize(
      find.widgetWithText(TextButton, l10n.listFinishedRacesTitle),
    );
    final right = tester.getSize(
      find.widgetWithText(FilledButton, l10n.listAddRace),
    );
    expect(left.width, right.width);
  });

  testWidgets('keeps the bar sixty logical pixels tall', (tester) async {
    // ARRANGE & ACT
    await pumpBar(tester, onNewRace: () {});

    // ASSERT
    expect(tester.getSize(find.byType(ListActionBar)).height, 60);
  });
}
