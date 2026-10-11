import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/shell/instruments_tab_status.dart';
import 'package:phone/features/shell/shell_tab.dart';
import 'package:phone/features/shell/widgets/shell_navigation_bar.dart';
import 'package:phone/features/shell/widgets/shell_tab_icon.dart';
import 'package:phone/l10n/app_localizations.dart';

void main() {
  late List<ShellTab> taps;

  setUp(() => taps = []);

  Future<void> pumpBar(
    WidgetTester tester, {
    ShellTab selected = ShellTab.races,
    InstrumentsTabStatus status = const InstrumentsTabStatus(
      link: InstrumentsLink.connected,
    ),
  }) {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        locale: const Locale('hu'),
        localizationsDelegates: phoneLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          bottomNavigationBar: ShellNavigationBar(
            selected: selected,
            status: status,
            onSelected: taps.add,
          ),
        ),
      ),
    );
  }

  Color iconColorOf(WidgetTester tester, ShellTab tab) => tester
      .widget<ShellTabIcon>(
        find.byWidgetPredicate((w) => w is ShellTabIcon && w.tab == tab),
      )
      .color;

  Color materialColorOf(WidgetTester tester, String label) => tester
      .widget<Material>(
        find
            .ancestor(of: find.text(label), matching: find.byType(Material))
            .first,
      )
      .color!;

  testWidgets('shows the three tabs in order, 64 high under a hairline', (
    tester,
  ) async {
    // ACT
    await pumpBar(tester);

    // ASSERT
    final races = tester.getCenter(find.text('Versenyek'));
    final instruments = tester.getCenter(find.text('Műszerek'));
    final log = tester.getCenter(find.text('Versenynapló'));
    expect(races.dx, lessThan(instruments.dx));
    expect(instruments.dx, lessThan(log.dx));
    expect(
      tester.getSize(find.byType(ShellNavigationBar)).height,
      ShellNavigationBar.height + 1,
    );
  });

  testWidgets('gives the middle cell 1.3 times the side width', (
    tester,
  ) async {
    // ACT
    await pumpBar(tester);

    // ASSERT — 412 dp: 124,8 + 162,4 + 124,8.
    final middle = tester.getSize(
      find
          .ancestor(of: find.text('Műszerek'), matching: find.byType(Expanded))
          .first,
    );
    expect(middle.width, closeTo(412 * 13 / 33, 0.5));
  });

  testWidgets('marks the selected tab white and the others quiet', (
    tester,
  ) async {
    // ACT
    await pumpBar(tester, selected: ShellTab.log);

    // ASSERT
    final scheme = foretackTheme.colorScheme;
    final tones = foretackTheme.extension<TextTones>()!;
    expect(iconColorOf(tester, ShellTab.log), scheme.onSurface);
    expect(iconColorOf(tester, ShellTab.races), tones.low);
    expect(
      iconColorOf(tester, ShellTab.instruments),
      scheme.onSecondaryContainer,
    );
  });

  testWidgets('reports the tapped tab', (tester) async {
    // ARRANGE
    await pumpBar(tester);

    // ACT
    await tester.tap(find.text('Műszerek'));
    await tester.tap(find.text('Versenynapló'));

    // ASSERT
    expect(taps, [ShellTab.instruments, ShellTab.log]);
  });

  testWidgets('shows the live label on a highlighted cell', (tester) async {
    // ACT
    await pumpBar(
      tester,
      status: const InstrumentsTabStatus(
        link: InstrumentsLink.connected,
        isLive: true,
      ),
    );

    // ASSERT
    expect(find.text('ÉLŐ'), findsOneWidget);
    expect(
      materialColorOf(tester, 'Műszerek'),
      foretackTheme.colorScheme.secondaryContainer,
    );
  });

  testWidgets("shows the day race's start time as given", (tester) async {
    // ARRANGE — a status mar helyi idot hordoz (instrumentsTabStatusOf).
    final start = DateTime(2026, 7, 30, 9, 5);

    // ACT
    await pumpBar(
      tester,
      status: InstrumentsTabStatus(
        link: InstrumentsLink.connected,
        scheduledStartAt: start,
      ),
    );

    // ASSERT
    expect(find.text('09:05'), findsOneWidget);
    expect(find.text('ÉLŐ'), findsNothing);
    expect(
      materialColorOf(tester, 'Műszerek'),
      foretackTheme.colorScheme.surfaceContainer,
    );
  });

  testWidgets('quiets the instruments icon without a link', (tester) async {
    // ACT
    await pumpBar(
      tester,
      status: const InstrumentsTabStatus(link: InstrumentsLink.disconnected),
    );

    // ASSERT
    final tones = foretackTheme.extension<TextTones>()!;
    expect(iconColorOf(tester, ShellTab.instruments), tones.low);
  });

  test('formats a clock time with two digits', () {
    expect(formatClock(DateTime(2026, 7, 30, 7, 3)), '07:03');
    expect(formatClock(DateTime(2026, 7, 30, 23, 45)), '23:45');
  });

  testWidgets('stays within the bar at a large text scale', (tester) async {
    // ARRANGE
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // ACT
    await pumpBar(tester);

    // ASSERT — a sav 1,3-ra korlatozza a nagyitast (a felirat kontextusa
    // 10-bol 13-at csinal, nem 20-at), es nincs tulcsordulas.
    final label = tester.element(find.text('Versenyek'));
    expect(MediaQuery.textScalerOf(label).scale(10), closeTo(13, 0.001));
    expect(tester.takeException(), isNull);
  });
}
