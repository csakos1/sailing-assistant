import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/race_setup/race_form_result.dart';
import 'package:phone/features/race_setup/start_time/start_time_sheet.dart';
import 'package:phone/features/race_setup/widgets/race_form.dart';
import 'package:phone/features/race_setup/widgets/start_point_empty_card.dart';
import 'package:phone/features/race_setup/widgets/start_time_card.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/widgets/foretack_switch.dart';

// A rajtido es a rajthely az urlapon (U7, 33a-33c). A "most" helyi ido,
// hogy a naptar napjai es a figyelmeztetes a teszt-gep zonajatol
// fuggetlenul ugyanazok legyenek.
void main() {
  const markA = Mark(
    sequence: 1,
    name: 'A',
    position: Coordinate(latitude: 46.9, longitude: 18),
  );
  const startPoint = StartPoint(
    name: 'Füredi rajt',
    position: Coordinate(latitude: 46.95, longitude: 17.9),
  );
  final morning = DateTime(2026, 10, 12, 8, 30);

  Future<void> pumpForm(
    WidgetTester tester, {
    required void Function(RaceFormResult result) onSubmit,
    Race? initialRace,
    DateTime? now,
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
          body: RaceForm(
            initialRace: initialRace,
            now: () => now ?? morning,
            onSubmit: onSubmit,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(RaceForm)))!;

  Future<void> save(WidgetTester tester) async {
    await tester.tap(
      find.widgetWithText(FilledButton, l10nOf(tester).setupSave),
    );
    await tester.pumpAndSettle();
  }

  // Mezok tree-sorrendben, rajthely nelkul: verseny-nev, boja-nev, lat, lon.
  Future<void> fillRaceWithOneMark(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'V');
    await tester.enterText(fields.at(1), 'Z1');
    await tester.enterText(fields.at(2), '46.9');
    await tester.enterText(fields.at(3), '18.05');
  }

  Race raceWith({DateTime? scheduledStartAt, StartPoint? startPoint}) =>
      Race.create(
        id: 'r1',
        name: 'V',
        marks: const [markA],
        scheduledStartAt: scheduledStartAt,
        startPoint: startPoint,
      );

  group('rajtidő', () {
    testWidgets('üresen az üres szöveg látszik, mentéskor null', (
      tester,
    ) async {
      // ARRANGE
      RaceFormResult? emitted;
      await pumpForm(tester, onSubmit: (result) => emitted = result);

      // ACT
      await fillRaceWithOneMark(tester);
      await save(tester);

      // ASSERT
      expect(find.text(l10nOf(tester).setupStartTimeEmpty), findsOneWidget);
      expect(emitted?.scheduledStartAt, isNull);
    });

    testWidgets('a választó a következő egész órán nyílik, a Kész átveszi', (
      tester,
    ) async {
      // ARRANGE
      RaceFormResult? emitted;
      await pumpForm(tester, onSubmit: (result) => emitted = result);
      await fillRaceWithOneMark(tester);

      // ACT
      await tester.tap(find.byType(StartTimeCard));
      await tester.pumpAndSettle();
      expect(find.byType(StartTimeSheet), findsOneWidget);
      await tester.tap(find.text(l10nOf(tester).startTimeSheetDone));
      await tester.pumpAndSettle();
      await save(tester);

      // ASSERT - 08:30 utan a 09:00 a kezdoertek; a kimenet UTC.
      expect(find.text('2026. okt. 12. · 09:00'), findsOneWidget);
      expect(emitted?.scheduledStartAt, DateTime(2026, 10, 12, 9).toUtc());
      expect(emitted?.scheduledStartAt?.isUtc, isTrue);
    });

    testWidgets('a választóban másik nap és óra választható', (tester) async {
      // ARRANGE
      RaceFormResult? emitted;
      await pumpForm(tester, onSubmit: (result) => emitted = result);
      await fillRaceWithOneMark(tester);

      // ACT - 15-e, egy oraval kesobb (az elso fel-nyil az ora).
      await tester.tap(find.byType(StartTimeCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nOf(tester).startTimeSheetDone));
      await tester.pumpAndSettle();
      await save(tester);

      // ASSERT
      expect(emitted?.scheduledStartAt, DateTime(2026, 10, 15, 10).toUtc());
    });

    testWidgets('a lap bezárása választás nélkül nem változtat', (
      tester,
    ) async {
      // ARRANGE
      await pumpForm(tester, onSubmit: (_) {});

      // ACT - a lap a hatter erintesevel zarul.
      await tester.tap(find.byType(StartTimeCard));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.byType(StartTimeSheet), findsNothing);
      expect(find.text(l10nOf(tester).setupStartTimeEmpty), findsOneWidget);
    });

    testWidgets('a „Nincs rajtidő" kiüríti a kitöltött mezőt', (tester) async {
      // ARRANGE
      RaceFormResult? emitted;
      final start = DateTime(2026, 10, 20, 9).toUtc();
      await pumpForm(
        tester,
        initialRace: raceWith(scheduledStartAt: start),
        onSubmit: (result) => emitted = result,
      );

      // ACT
      await tester.tap(find.byType(StartTimeCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nOf(tester).startTimeSheetClear));
      await tester.pumpAndSettle();
      await save(tester);

      // ASSERT
      expect(emitted?.scheduledStartAt, isNull);
    });

    testWidgets('a „×" kiüríti a mezőt', (tester) async {
      // ARRANGE
      RaceFormResult? emitted;
      final start = DateTime(2026, 10, 20, 9).toUtc();
      await pumpForm(
        tester,
        initialRace: raceWith(scheduledStartAt: start),
        onSubmit: (result) => emitted = result,
      );

      // ACT
      await tester.tap(find.byTooltip(l10nOf(tester).setupStartTimeClear));
      await tester.pumpAndSettle();
      await save(tester);

      // ASSERT
      expect(find.text(l10nOf(tester).setupStartTimeEmpty), findsOneWidget);
      expect(emitted?.scheduledStartAt, isNull);
    });

    testWidgets('edit módban a rajtidő változatlanul megmarad', (
      tester,
    ) async {
      // ARRANGE
      RaceFormResult? emitted;
      final start = DateTime(2026, 10, 20, 9).toUtc();
      await pumpForm(
        tester,
        initialRace: raceWith(scheduledStartAt: start),
        onSubmit: (result) => emitted = result,
      );

      // ACT
      await save(tester);

      // ASSERT - helyi idoben mutatja, a kimenet ugyanaz a pillanat.
      expect(find.text('2026. okt. 20. · 09:00'), findsOneWidget);
      expect(emitted?.scheduledStartAt, start);
    });

    testWidgets('jövőbeli rajtidőnél nincs figyelmeztetés', (tester) async {
      // ARRANGE & ACT
      await pumpForm(
        tester,
        initialRace: raceWith(
          scheduledStartAt: DateTime(2026, 10, 12, 9).toUtc(),
        ),
        onSubmit: (_) {},
      );

      // ASSERT
      final l10n = l10nOf(tester);
      expect(find.text(l10n.setupStartTimePastRetroactive), findsNothing);
      expect(find.text(l10n.setupStartTimePastManual), findsNothing);
    });

    testWidgets('ma, a késési ablakon belül: visszamenőleges jelzés', (
      tester,
    ) async {
      // ARRANGE & ACT - 09:00-s rajt, 10:00 most (az ablak 3 ora).
      await pumpForm(
        tester,
        initialRace: raceWith(
          scheduledStartAt: DateTime(2026, 10, 12, 9).toUtc(),
        ),
        now: DateTime(2026, 10, 12, 10),
        onSubmit: (_) {},
      );

      // ASSERT
      expect(
        find.text(l10nOf(tester).setupStartTimePastRetroactive),
        findsOneWidget,
      );
    });

    testWidgets('az ablakon túl: kézi indítás jelzése, a mentés megy', (
      tester,
    ) async {
      // ARRANGE
      RaceFormResult? emitted;
      final start = DateTime(2026, 10, 11, 9).toUtc();
      await pumpForm(
        tester,
        initialRace: raceWith(scheduledStartAt: start),
        onSubmit: (result) => emitted = result,
      );

      // ACT
      await save(tester);

      // ASSERT - a multbeli ido mentheto (ADR 0055 D9).
      expect(
        find.text(l10nOf(tester).setupStartTimePastManual),
        findsOneWidget,
      );
      expect(emitted?.scheduledStartAt, start);
    });
  });

  group('rajthely', () {
    testWidgets('üresen az üres kártya látszik, mentéskor null', (
      tester,
    ) async {
      // ARRANGE
      RaceFormResult? emitted;
      await pumpForm(tester, onSubmit: (result) => emitted = result);

      // ACT
      await fillRaceWithOneMark(tester);
      await save(tester);

      // ASSERT
      expect(find.byType(StartPointEmptyCard), findsOneWidget);
      expect(emitted?.startPoint, isNull);
    });

    testWidgets('a „Koordináta" út üres mezőket ad, fókusz a néven', (
      tester,
    ) async {
      // ARRANGE
      await pumpForm(tester, onSubmit: (_) {});
      expect(find.byType(TextFormField), findsNWidgets(4));

      // ACT
      await tester.tap(find.text(l10nOf(tester).setupStartPointCoordinates));
      await tester.pumpAndSettle();

      // ASSERT - nev + rajthely 3 mezo + boja 3 mezo; a fokusz a rajthely
      // neven (a masodik szovegmezo).
      expect(find.byType(StartPointEmptyCard), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(7));
      final nameField = tester.widget<EditableText>(
        find.byType(EditableText).at(1),
      );
      expect(nameField.focusNode.hasFocus, isTrue);
    });

    testWidgets('a beírt rajthely a kimenetbe kerül', (tester) async {
      // ARRANGE
      RaceFormResult? emitted;
      await pumpForm(tester, onSubmit: (result) => emitted = result);
      await tester.tap(find.text(l10nOf(tester).setupStartPointCoordinates));
      await tester.pumpAndSettle();

      // ACT - nev, rajthely (nev, lat, lon), boja (nev, lat, lon).
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'V');
      await tester.enterText(fields.at(1), ' Füredi rajt ');
      await tester.enterText(fields.at(2), "46° 57' N");
      await tester.enterText(fields.at(3), '17.9');
      await tester.enterText(fields.at(4), 'Z1');
      await tester.enterText(fields.at(5), '46.9');
      await tester.enterText(fields.at(6), '18.05');
      await save(tester);

      // ASSERT - a nev trimmelve, a DDM fokra alakitva.
      expect(emitted?.startPoint?.name, 'Füredi rajt');
      expect(emitted?.startPoint?.position.latitude, closeTo(46.95, 1e-9));
      expect(emitted?.startPoint?.position.longitude, 17.9);
      expect(emitted?.marks.single.name, 'Z1');
    });

    testWidgets('üres rajthely-név blokkolja a mentést', (tester) async {
      // ARRANGE
      var submitted = false;
      await pumpForm(tester, onSubmit: (_) => submitted = true);
      await tester.tap(find.text(l10nOf(tester).setupStartPointCoordinates));
      await tester.pumpAndSettle();

      // ACT - a rajthely neve marad uresen.
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'V');
      await tester.enterText(fields.at(2), '46.95');
      await tester.enterText(fields.at(3), '17.9');
      await tester.enterText(fields.at(4), 'Z1');
      await tester.enterText(fields.at(5), '46.9');
      await tester.enterText(fields.at(6), '18.05');
      await save(tester);

      // ASSERT
      expect(submitted, isFalse);
    });

    testWidgets('a „×" visszaadja az üres kártyát, mentéskor null', (
      tester,
    ) async {
      // ARRANGE
      RaceFormResult? emitted;
      await pumpForm(
        tester,
        initialRace: raceWith(startPoint: startPoint),
        onSubmit: (result) => emitted = result,
      );

      // ACT
      await tester.tap(find.byTooltip(l10nOf(tester).setupStartPointRemove));
      await tester.pumpAndSettle();
      await save(tester);

      // ASSERT - a regi kontrollerek a frame vegen szabadulnak fel.
      expect(find.byType(StartPointEmptyCard), findsOneWidget);
      expect(emitted?.startPoint, isNull);
    });

    testWidgets('edit módban a rajthely feltöltve, változatlanul megmarad', (
      tester,
    ) async {
      // ARRANGE
      RaceFormResult? emitted;
      await pumpForm(
        tester,
        initialRace: raceWith(startPoint: startPoint),
        onSubmit: (result) => emitted = result,
      );

      // ACT
      await save(tester);

      // ASSERT
      expect(find.text('Füredi rajt'), findsOneWidget);
      expect(find.text('46.95'), findsOneWidget);
      expect(emitted?.startPoint, startPoint);
    });

    testWidgets('bója nélküli versenyen is megmarad (ADR 0055 D1)', (
      tester,
    ) async {
      // ARRANGE
      RaceFormResult? emitted;
      await pumpForm(
        tester,
        initialRace: raceWith(startPoint: startPoint),
        onSubmit: (result) => emitted = result,
      );

      // ACT
      await tester.tap(find.byType(ForetackSwitch));
      await tester.pumpAndSettle();
      await save(tester);

      // ASSERT
      expect(emitted?.marks, isEmpty);
      expect(emitted?.startPoint, startPoint);
    });
  });
}
