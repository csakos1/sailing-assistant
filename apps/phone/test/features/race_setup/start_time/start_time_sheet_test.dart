import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/race_setup/start_time/start_time_sheet.dart';
import 'package:phone/l10n/app_localizations.dart';

// A lapot a valodi belepon (showStartTimeSheet) at nyitjuk, hogy a
// visszaadott rekord is ellenorizheto legyen.
void main() {
  final today = DateTime(2026, 10, 12, 8, 30);
  // A lap eredmenye; az async segedbol visszaadva a Future kibontodna, es
  // a teszt a lap bezarasaig varna.
  late Future<StartTimeChoice?> result;

  Future<void> openSheet(
    WidgetTester tester, {
    required DateTime initial,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        locale: const Locale('hu'),
        localizationsDelegates: phoneLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => result = showStartTimeSheet(
                context,
                initial: initial,
                today: today,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(StartTimeSheet)))!;

  Future<void> tapDone(WidgetTester tester) async {
    await tester.tap(find.text(l10nOf(tester).startTimeSheetDone));
    await tester.pumpAndSettle();
  }

  Finder arrow(IconData icon, int index) => find.byIcon(icon).at(index);

  testWidgets('shows the initial value, month and weekdays', (tester) async {
    // ARRANGE & ACT
    await openSheet(tester, initial: DateTime(2026, 10, 12, 9));

    // ASSERT - a fejlec, a honap-sor es a hetfo-kezdetu fejlec.
    expect(find.text('2026. okt. 12. · 09:00'), findsOneWidget);
    expect(find.text('2026. OKTÓBER'), findsOneWidget);
    expect(find.text('H'), findsOneWidget);
    expect(find.text('V'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
  });

  testWidgets('returns the initial value unchanged on done', (tester) async {
    // ARRANGE
    await openSheet(tester, initial: DateTime(2026, 10, 12, 9));

    // ACT
    await tapDone(tester);

    // ASSERT
    expect((await result)?.localStart, DateTime(2026, 10, 12, 9));
  });

  testWidgets('returns a null start on the clear button', (tester) async {
    // ARRANGE
    await openSheet(tester, initial: DateTime(2026, 10, 12, 9));

    // ACT
    await tester.tap(find.text(l10nOf(tester).startTimeSheetClear));
    await tester.pumpAndSettle();

    // ASSERT - a rekord megvan, csak az ideje null (kiurites, nem bezaras).
    final choice = await result;
    expect(choice, isNotNull);
    expect(choice?.localStart, isNull);
  });

  testWidgets('returns null when dismissed without a choice', (tester) async {
    // ARRANGE
    await openSheet(tester, initial: DateTime(2026, 10, 12, 9));

    // ACT
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // ASSERT
    expect(await result, isNull);
  });

  testWidgets('selects another day and keeps the time', (tester) async {
    // ARRANGE
    await openSheet(tester, initial: DateTime(2026, 10, 12, 9));

    // ACT
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();

    // ASSERT - a fejlec azonnal kovet, a Kesz ezt adja vissza.
    expect(find.text('2026. okt. 20. · 09:00'), findsOneWidget);
    await tapDone(tester);
    expect((await result)?.localStart, DateTime(2026, 10, 20, 9));
  });

  testWidgets('pages the month and selects a day there', (tester) async {
    // ARRANGE
    await openSheet(tester, initial: DateTime(2026, 12, 30, 9));

    // ACT - a kovetkezo honap a kovetkezo evbe esik.
    await tester.tap(find.byTooltip(l10nOf(tester).startTimeSheetNextMonth));
    await tester.pumpAndSettle();
    expect(find.text('2027. JANUÁR'), findsOneWidget);
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    await tapDone(tester);

    // ASSERT
    expect((await result)?.localStart, DateTime(2027, 1, 2, 9));
  });

  testWidgets('wraps the hour and the minute with the steppers', (
    tester,
  ) async {
    // ARRANGE - 23:59, igy mindket fel-nyil korbefordul.
    await openSheet(tester, initial: DateTime(2026, 10, 12, 23, 59));

    // ACT - az elso fel-nyil az ora, a masodik a perc.
    await tester.tap(arrow(Icons.keyboard_arrow_up, 0));
    await tester.tap(arrow(Icons.keyboard_arrow_up, 1));
    await tester.pumpAndSettle();

    // ASSERT - a nap nem lep at: a lepteto csak az orat es a percet allitja.
    expect(find.text('2026. okt. 12. · 00:00'), findsOneWidget);
    await tapDone(tester);
    expect((await result)?.localStart, DateTime(2026, 10, 12));
  });

  testWidgets('steps down below zero to the end of the range', (
    tester,
  ) async {
    // ARRANGE
    await openSheet(tester, initial: DateTime(2026, 10, 12));

    // ACT
    await tester.tap(arrow(Icons.keyboard_arrow_down, 0));
    await tester.tap(arrow(Icons.keyboard_arrow_down, 1));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('23'), findsWidgets);
    expect(find.text('59'), findsOneWidget);
  });

  testWidgets('repeats the step while the arrow is held', (tester) async {
    // ARRANGE
    await openSheet(tester, initial: DateTime(2026, 10, 12, 9));

    // ACT - hosszu nyomas a perc fel-nyilan: 1 azonnal, majd 150 ms-onkent.
    final gesture = await tester.startGesture(
      tester.getCenter(arrow(Icons.keyboard_arrow_up, 1)),
    );
    await tester.pump(kLongPressTimeout);
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump(const Duration(milliseconds: 150));
    await gesture.up();
    await tester.pumpAndSettle();

    // ASSERT - a felengedes utan nem lep tovabb.
    expect(find.text('2026. okt. 12. · 09:03'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2026. okt. 12. · 09:03'), findsOneWidget);
  });

  testWidgets('labels the stepper arrows for accessibility', (tester) async {
    // ARRANGE
    final handle = tester.ensureSemantics();
    await openSheet(tester, initial: DateTime(2026, 10, 12, 9));
    final l10n = l10nOf(tester);

    // ASSERT - egy-egy gomb-felirat, nem duplazva.
    expect(find.bySemanticsLabel(l10n.startTimeSheetHourUp), findsOneWidget);
    expect(
      find.bySemanticsLabel(l10n.startTimeSheetMinuteDown),
      findsOneWidget,
    );
    handle.dispose();
  });
}
