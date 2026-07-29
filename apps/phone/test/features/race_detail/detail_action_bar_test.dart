import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_detail/widgets/detail_action_bar.dart';
import 'package:phone/l10n/app_localizations.dart';

void main() {
  Future<void> pumpBar(
    WidgetTester tester,
    RaceStatus status, {
    VoidCallback? onOpenLive,
    VoidCallback? onStatusAction,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        locale: const Locale('hu'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: DetailActionBar(
              status: status,
              onOpenLive: onOpenLive ?? () {},
              onStatusAction: onStatusAction ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(DetailActionBar)))!;

  // Egy sor hattere: a Material szinet olvassuk, mert a kitoltest az adja.
  Color backgroundOf(WidgetTester tester, String label) {
    final row = find.ancestor(
      of: find.text(label),
      matching: find.byType(Material),
    );
    return tester.widget<Material>(row.first).color!;
  }

  testWidgets('emphasises the start row before the race', (tester) async {
    // ARRANGE & ACT
    await pumpBar(tester, RaceStatus.notStarted);

    // ASSERT
    final l10n = l10nOf(tester);
    final scheme = foretackTheme.colorScheme;
    expect(backgroundOf(tester, l10n.detailStart), scheme.primary);
    expect(backgroundOf(tester, l10n.liveOpen), scheme.surfaceContainer);
  });

  testWidgets('emphasises the live row while the race runs', (tester) async {
    // ARRANGE & ACT
    await pumpBar(tester, RaceStatus.active);

    // ASSERT - futas kozben a visszaugras az elo nezetre a gyakori akcio.
    final l10n = l10nOf(tester);
    final scheme = foretackTheme.colorScheme;
    expect(backgroundOf(tester, l10n.liveOpen), scheme.primary);
    expect(backgroundOf(tester, l10n.detailFinish), scheme.surfaceContainer);
  });

  testWidgets('fills exactly one row in either state', (tester) async {
    // ARRANGE & ACT & ASSERT - ez a sav lenyege: ket teal sav nem
    // rangsorolna, ket semleges pedig semmit nem ajanlana.
    final scheme = foretackTheme.colorScheme;
    final filled = find.byWidgetPredicate(
      (widget) => widget is Material && widget.color == scheme.primary,
    );

    await pumpBar(tester, RaceStatus.notStarted);
    expect(filled, findsOneWidget);

    await pumpBar(tester, RaceStatus.active);
    expect(filled, findsOneWidget);
  });

  testWidgets('swaps the status label with the status', (tester) async {
    // ARRANGE & ACT
    await pumpBar(tester, RaceStatus.notStarted);

    // ASSERT
    final l10n = l10nOf(tester);
    expect(find.text(l10n.detailStart), findsOneWidget);
    expect(find.text(l10n.detailFinish), findsNothing);

    // ACT
    await pumpBar(tester, RaceStatus.active);

    // ASSERT
    expect(find.text(l10n.detailFinish), findsOneWidget);
    expect(find.text(l10n.detailStart), findsNothing);
  });

  testWidgets('stands 121 dp tall with 60 dp rows', (tester) async {
    // ARRANGE & ACT
    await pumpBar(tester, RaceStatus.notStarted);

    // ASSERT - 60 + 1 valaszto + 60; felso hairline nincs, azt a fenti
    // boja-sor sajat vonala adja.
    expect(tester.getSize(find.byType(DetailActionBar)).height, 121);
    for (final label in [l10nOf(tester).liveOpen, l10nOf(tester).detailStart]) {
      final box = find.ancestor(
        of: find.text(label),
        matching: find.byType(SizedBox),
      );
      expect(tester.getSize(box.first).height, 60, reason: label);
    }
  });

  testWidgets('routes each row to its own callback', (tester) async {
    // ARRANGE
    var liveTaps = 0;
    var actionTaps = 0;
    await pumpBar(
      tester,
      RaceStatus.active,
      onOpenLive: () => liveTaps++,
      onStatusAction: () => actionTaps++,
    );
    final l10n = l10nOf(tester);

    // ACT
    await tester.tap(find.text(l10n.liveOpen));
    await tester.pump();

    // ASSERT
    expect(liveTaps, 1);
    expect(actionTaps, 0);

    // ACT
    await tester.tap(find.text(l10n.detailFinish));
    await tester.pump();

    // ASSERT
    expect(actionTaps, 1);
    expect(liveTaps, 1);
  });

  testWidgets('refuses to render for a finished race', (tester) async {
    // ARRANGE & ACT
    await pumpBar(tester, RaceStatus.finished);

    // ASSERT - befejezett versenyen nincs also sav, es a widget ezt nem
    // csendben nyeli le.
    expect(tester.takeException(), isAssertionError);
  });
}
