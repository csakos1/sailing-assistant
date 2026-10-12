import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/race_detail/widgets/detail_action_bar.dart';
import 'package:phone/l10n/app_localizations.dart';

void main() {
  Future<void> pumpBar(WidgetTester tester, DetailActionBar bar) {
    return tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        locale: const Locale('hu'),
        localizationsDelegates: phoneLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(alignment: Alignment.bottomCenter, child: bar),
        ),
      ),
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(DetailActionBar)))!;

  // Egy cella hattere: a Material szinet olvassuk, mert a kitoltest az adja.
  Color backgroundOf(WidgetTester tester, String label) {
    final cell = find.ancestor(
      of: find.text(label),
      matching: find.byType(Material),
    );
    return tester.widget<Material>(cell.first).color!;
  }

  testWidgets('splits the scheduled start into the time and start now', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpBar(
      tester,
      DetailActionBar.scheduled(automaticStartLabel: '09:00', onStart: () {}),
    );
    final l10n = l10nOf(tester);

    // ASSERT - 32a: a bal cella csak tajekoztat, a jobb a kitoltott rajt.
    expect(find.text(l10n.detailAutomaticStart), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(
      backgroundOf(tester, l10n.detailStartNow),
      foretackTheme.colorScheme.primary,
    );
    final startNow = tester.getRect(
      find
          .ancestor(
            of: find.text(l10n.detailStartNow),
            matching: find.byType(Material),
          )
          .first,
    );
    // 10 : 13 aranyban: 800 * 13 / 23.
    expect(startNow.width, closeTo(800 * 13 / 23, 1));
  });

  testWidgets('routes a tap on start now to the start', (tester) async {
    // ARRANGE
    var starts = 0;
    await pumpBar(
      tester,
      DetailActionBar.scheduled(
        automaticStartLabel: '09:00',
        onStart: () => starts++,
      ),
    );

    // ACT - a tajekoztato cella nem indit.
    await tester.tap(find.text('09:00'));
    await tester.tap(find.text(l10nOf(tester).detailStartNow));
    await tester.pump();

    // ASSERT
    expect(starts, 1);
  });

  testWidgets('fills the manual start without a scheduled start', (
    tester,
  ) async {
    // ARRANGE
    var starts = 0;
    await pumpBar(tester, DetailActionBar.start(onStart: () => starts++));
    final l10n = l10nOf(tester);

    // ACT
    await tester.tap(find.text(l10n.detailStart));
    await tester.pump();

    // ASSERT - 32c
    expect(
      backgroundOf(tester, l10n.detailStart),
      foretackTheme.colorScheme.primary,
    );
    expect(find.text(l10n.detailAutomaticStart), findsNothing);
    expect(starts, 1);
  });

  testWidgets('keeps the finish neutral while the race runs', (tester) async {
    // ARRANGE
    var finishes = 0;
    await pumpBar(tester, DetailActionBar.finish(onFinish: () => finishes++));
    final l10n = l10nOf(tester);

    // ACT
    await tester.tap(find.text(l10n.detailFinish));
    await tester.pump();

    // ASSERT - 32b: semleges, hogy a vizen egy veletlen erintes ne hivja.
    expect(
      backgroundOf(tester, l10n.detailFinish),
      foretackTheme.colorScheme.surfaceContainer,
    );
    expect(finishes, 1);
  });

  testWidgets('stands 62 dp tall', (tester) async {
    // ARRANGE & ACT
    await pumpBar(tester, DetailActionBar.start(onStart: () {}));

    // ASSERT
    expect(tester.getSize(find.byType(DetailActionBar)).height, 62);
  });
}
