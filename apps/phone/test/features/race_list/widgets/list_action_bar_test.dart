import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/race_list/widgets/list_action_bar.dart';
import 'package:phone/l10n/app_localizations.dart';

void main() {
  Future<void> pumpBar(WidgetTester tester, {required VoidCallback onNewRace}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        locale: const Locale('hu'),
        localizationsDelegates: phoneLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              const Spacer(),
              ListActionBar(onNewRace: onNewRace),
            ],
          ),
        ),
      ),
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ListActionBar)))!;

  testWidgets('reports a tap on the new race button', (tester) async {
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

  testWidgets('spans the full width without a log half', (tester) async {
    // ARRANGE & ACT
    await pumpBar(tester, onNewRace: () {});
    final l10n = l10nOf(tester);

    // ASSERT - a naplo a hej sajat fule lett (ADR 0056 D2).
    expect(find.byType(TextButton), findsNothing);
    expect(
      tester.getSize(find.widgetWithText(FilledButton, l10n.listAddRace)).width,
      tester.getSize(find.byType(ListActionBar)).width,
    );
  });

  testWidgets('keeps the bar 56 logical pixels tall', (tester) async {
    // ARRANGE & ACT
    await pumpBar(tester, onNewRace: () {});

    // ASSERT - makett 31a.
    expect(tester.getSize(find.byType(ListActionBar)).height, 56);
  });

  testWidgets('labels the button at 15 / w700', (tester) async {
    // ARRANGE & ACT
    await pumpBar(tester, onNewRace: () {});
    final l10n = l10nOf(tester);

    // ASSERT
    final style = DefaultTextStyle.of(
      tester.element(find.text(l10n.listAddRace)),
    ).style;
    expect(style.fontSize, 15);
    expect(style.fontWeight, FontWeight.w700);
  });
}
