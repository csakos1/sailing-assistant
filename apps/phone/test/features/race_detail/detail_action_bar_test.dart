import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/race_detail/widgets/detail_action_bar.dart';
import 'package:phone/l10n/app_localizations.dart';

void main() {
  Future<void> pumpBar(
    WidgetTester tester,
    RaceStatus status, {
    VoidCallback? onStatusAction,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        locale: const Locale('hu'),
        localizationsDelegates: phoneLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: DetailActionBar(
              status: status,
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

  testWidgets('fills the start row before the race', (tester) async {
    // ARRANGE & ACT
    await pumpBar(tester, RaceStatus.notStarted);

    // ASSERT
    final l10n = l10nOf(tester);
    expect(
      backgroundOf(tester, l10n.detailStart),
      foretackTheme.colorScheme.primary,
    );
  });

  testWidgets('keeps the finish row neutral while the race runs', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpBar(tester, RaceStatus.active);

    // ASSERT
    final l10n = l10nOf(tester);
    expect(
      backgroundOf(tester, l10n.detailFinish),
      foretackTheme.colorScheme.surfaceContainer,
    );
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

  testWidgets('stands one 60 dp row tall', (tester) async {
    // ARRANGE & ACT
    await pumpBar(tester, RaceStatus.notStarted);

    // ASSERT - az Elo nezet sora megszunt (ADR 0056 D2).
    expect(tester.getSize(find.byType(DetailActionBar)).height, 60);
  });

  testWidgets('routes a tap to the status action', (tester) async {
    // ARRANGE
    var actionTaps = 0;
    await pumpBar(
      tester,
      RaceStatus.active,
      onStatusAction: () => actionTaps++,
    );
    final l10n = l10nOf(tester);

    // ACT
    await tester.tap(find.text(l10n.detailFinish));
    await tester.pump();

    // ASSERT
    expect(actionTaps, 1);
  });

  testWidgets('refuses to render for a finished race', (tester) async {
    // ARRANGE & ACT
    await pumpBar(tester, RaceStatus.finished);

    // ASSERT - befejezett versenyen nincs also sav, es a widget ezt nem
    // csendben nyeli le.
    expect(tester.takeException(), isAssertionError);
  });
}
