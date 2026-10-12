import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/shell/day_race_provider.dart';
import 'package:phone/features/shell/instruments_tab_status.dart';
import 'package:phone/features/shell/instruments_tab_status_provider.dart';
import 'package:phone/features/shell/phone_shell.dart';
import 'package:phone/features/shell/shell_tab.dart';
import 'package:phone/features/shell/shell_tab_provider.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/pending_race_deletions_provider.dart';
import 'package:phone/providers/race_start_signal_provider.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.9, longitude: 18.05),
  );
  final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
  final startedAt = DateTime.utc(2026, 7, 30, 7);
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        // A sav allapota sajat teszteben; itt csak a hej viselkedese szamit.
        instrumentsTabStatusProvider.overrideWith(
          (ref) => const InstrumentsTabStatus(link: InstrumentsLink.connected),
        ),
        dayRaceProvider.overrideWith((ref) => null),
      ],
    );
    addTearDown(container.dispose);
  });

  // A fulek helyett egyszeru feliratok; a Versenyek ful egy gombbal
  // push-ol egy kepernyot (mint a reszlet).
  Future<void> pumpShell(WidgetTester tester, {Widget? pushed}) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: foretackTheme,
          locale: const Locale('hu'),
          localizationsDelegates: phoneLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhoneShell(
            races: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        pushed ?? const Scaffold(body: Text('detail')),
                  ),
                ),
                child: const Text('races'),
              ),
            ),
            instruments: const Text('instruments'),
            log: const Text('log'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the races tab', (tester) async {
    // ACT
    await pumpShell(tester);

    // ASSERT
    expect(find.text('races'), findsOneWidget);
    expect(find.text('instruments'), findsNothing);
  });

  testWidgets('switches tabs from the bar', (tester) async {
    // ARRANGE
    await pumpShell(tester);

    // ACT
    await tester.tap(find.text('Versenynapló'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('log'), findsOneWidget);
    expect(find.text('races'), findsNothing);
  });

  testWidgets('builds the instruments only while selected', (tester) async {
    // ARRANGE
    await pumpShell(tester);
    await tester.tap(find.text('Műszerek'));
    await tester.pumpAndSettle();
    expect(find.text('instruments'), findsOneWidget);

    // ACT
    await tester.tap(find.text('Versenyek'));
    await tester.pumpAndSettle();

    // ASSERT — nem csak rejtett: a fabol is kikerult (a wakelock miatt).
    expect(find.text('instruments', skipOffstage: false), findsNothing);
  });

  testWidgets('builds the log only once it is opened', (tester) async {
    // ACT
    await pumpShell(tester);

    // ASSERT — hideg indulaskor a naplo DB-olvasasa nem indul el.
    expect(find.text('log', skipOffstage: false), findsNothing);
  });

  testWidgets('keeps the log alive off screen once opened', (tester) async {
    // ARRANGE
    await pumpShell(tester);
    await tester.tap(find.text('Versenynapló'));
    await tester.pumpAndSettle();

    // ACT
    await tester.tap(find.text('Versenyek'));
    await tester.pumpAndSettle();

    // ASSERT — rejtve, de a faban (gorgetes, kivalasztott ev megmarad).
    expect(find.text('log'), findsNothing);
    expect(find.text('log', skipOffstage: false), findsOneWidget);
  });

  testWidgets('back on another tab goes to the races tab', (tester) async {
    // ARRANGE
    await pumpShell(tester);
    await tester.tap(find.text('Versenynapló'));
    await tester.pumpAndSettle();

    // ACT
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // ASSERT — a hej nem lep ki, a Versenyekre valt.
    expect(handled, isTrue);
    expect(find.text('races'), findsOneWidget);
  });

  testWidgets('back on the races tab leaves the app', (tester) async {
    // ARRANGE
    await pumpShell(tester);

    // ACT
    final handled = await tester.binding.handlePopRoute();

    // ASSERT — a gyoker utvonalat a rendszer zarja (a kotelezo valasz
    // `false`: senki nem kezelte).
    expect(handled, isFalse);
  });

  testWidgets('a start switches to the instruments and closes pushes', (
    tester,
  ) async {
    // ARRANGE — a reszlet a hej folott.
    await pumpShell(tester);
    await tester.tap(find.text('races'));
    await tester.pumpAndSettle();
    expect(find.text('detail'), findsOneWidget);

    // ACT
    container.read(raceStartSignalProvider.notifier).signal('r1');
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('detail'), findsNothing);
    expect(find.text('instruments'), findsOneWidget);
  });

  testWidgets('every start switches again', (tester) async {
    // ARRANGE — az elso rajt utan a felhasznalo visszalep a Versenyekre.
    await pumpShell(tester);
    container.read(raceStartSignalProvider.notifier).signal('r1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Versenyek'));
    await tester.pumpAndSettle();

    // ACT
    container.read(raceStartSignalProvider.notifier).signal('r2');
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('instruments'), findsOneWidget);
  });

  testWidgets('selecting a running race is not a start', (tester) async {
    // ARRANGE — pl. a Cel elotti kivalasztas: a kivalasztas valtozik, de
    // rajt-jelzes nincs.
    await pumpShell(tester);

    // ACT
    container.read(activeRaceProvider.notifier).activeRace = race.start(
      at: startedAt,
    );
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('races'), findsOneWidget);
  });

  testWidgets('a finish does not switch tabs', (tester) async {
    // ARRANGE
    await pumpShell(tester);
    final started = race.start(at: startedAt);
    container.read(activeRaceProvider.notifier).activeRace = started;
    await tester.pumpAndSettle();

    // ACT
    container.read(activeRaceProvider.notifier).activeRace = started.finish(
      at: startedAt.add(const Duration(hours: 2)),
    );
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('races'), findsOneWidget);
  });

  testWidgets('a start leaves a screen that refuses to close', (
    tester,
  ) async {
    // ARRANGE — egy kepernyo, ami nem engedi a bezarast (pl. a
    // helyreallito kodok).
    await pumpShell(
      tester,
      pushed: const PopScope(
        canPop: false,
        child: Scaffold(body: Text('codes')),
      ),
    );
    await tester.tap(find.text('races'));
    await tester.pumpAndSettle();

    // ACT
    container.read(raceStartSignalProvider.notifier).signal('r1');
    await tester.pumpAndSettle();

    // ASSERT — a ful valtott, a kepernyo a helyen maradt.
    expect(find.text('codes'), findsOneWidget);
    expect(container.read(shellTabProvider), ShellTab.instruments);
  });

  testWidgets('going to the background cancels pending deletions', (
    tester,
  ) async {
    // ARRANGE - egy fuggo torles a VISSZAVONAS-snackbarral.
    await pumpShell(tester);
    container.read(pendingRaceDeletionsProvider.notifier).schedule('r1');
    ScaffoldMessenger.of(
      tester.element(find.text('races')),
    ).showSnackBar(const SnackBar(content: Text('deleted')));
    await tester.pumpAndSettle();
    expect(find.text('deleted'), findsOneWidget);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );

    // ACT
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);

    // ASSERT - a torles elmarad.
    expect(container.read(pendingRaceDeletionsProvider), isEmpty);

    // ACT - visszateres: `hidden` alatt nincs kepkocka, a snackbar
    // eltunese csak ezutan animal le.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();

    // ASSERT - a snackbar mar nem igerhet semmit.
    expect(find.text('deleted'), findsNothing);
  });

  testWidgets('a pulled-down shade keeps pending deletions', (tester) async {
    // ARRANGE
    await pumpShell(tester);
    container.read(pendingRaceDeletionsProvider.notifier).schedule('r1');
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );

    // ACT - az ertesitesi sav csak `inactive`.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    // ASSERT
    expect(container.read(pendingRaceDeletionsProvider), {'r1'});
    container.read(pendingRaceDeletionsProvider.notifier).cancelAll();
  });
}
