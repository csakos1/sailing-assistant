import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';

void main() {
  // Egy gomb mutatja a snackbart; a `build` a snackbart a gomb
  // contextjebol kesziti.
  Future<void> pumpShower(
    WidgetTester tester,
    SnackBar Function(BuildContext context) build,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  ScaffoldMessenger.of(context).showSnackBar(build(context)),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    // A belepo animacio 250 ms; utana a snackbar teljes merete all.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder countdownFill() => find.byType(FractionallySizedBox);

  group('foretackSnackBar', () {
    testWidgets('shows the message in a 52 high square bar', (tester) async {
      // ACT
      await pumpShower(
        tester,
        (context) => foretackSnackBar(context, message: 'Kodok masolva'),
      );

      // ASSERT
      expect(find.text('Kodok masolva'), findsOneWidget);
      final material = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Kodok masolva'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, foretackTheme.colorScheme.surfaceContainerHigh);
      expect(material.elevation, 0);
      // A foretackSnackBar mindig ad format, ezert nem null.
      final shape = material.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.zero);
      expect(shape.side.color, foretackTheme.colorScheme.outline);
      expect(
        tester.getSize(find.byType(SnackBar)).height,
        // A 12 dp-s also margo es a 2 x 1 dp-s keret-betet a SnackBar
        // meretebe tartozik.
        foretackSnackBarMinHeight + 2 + 12,
      );
    });

    testWidgets('paints the status mark neutral by default', (tester) async {
      // ACT
      await pumpShower(
        tester,
        (context) => foretackSnackBar(context, message: 'Mentve'),
      );

      // ASSERT
      final mark = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(SnackBar),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(mark.color, foretackTheme.colorScheme.onSurfaceVariant);
    });

    testWidgets('paints the status mark in the given colour', (tester) async {
      // ACT
      await pumpShower(
        tester,
        (context) => foretackSnackBar(
          context,
          message: 'Nem sikerult',
          markColor: foretackTheme.colorScheme.error,
        ),
      );

      // ASSERT
      final mark = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(SnackBar),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(mark.color, foretackTheme.colorScheme.error);
    });

    testWidgets('grows when a long detail line wraps', (tester) async {
      // ARRANGE — a tesztbetuvel a sor tobbszor tordel.
      final detail = 'Firefox · Linux · Budapest, HU · ' * 6;

      // ACT
      await pumpShower(
        tester,
        (context) => foretackSnackBar(
          context,
          message: 'Belepve a webre',
          detail: detail,
        ),
      );

      // ASSERT
      expect(find.text(detail), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(SnackBar)).height,
        greaterThan(foretackSnackBarMinHeight + 2 + 12 + 10),
      );
    });

    testWidgets('has no action cell and no countdown without an action', (
      tester,
    ) async {
      // ACT
      await pumpShower(
        tester,
        (context) => foretackSnackBar(context, message: 'Mentve'),
      );

      // ASSERT
      expect(countdownFill(), findsNothing);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });

    testWidgets('closes after its duration', (tester) async {
      // ARRANGE
      await pumpShower(
        tester,
        (context) => foretackSnackBar(context, message: 'Mentve'),
      );

      // ACT
      await tester.pump(foretackSnackBarDuration);
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Mentve'), findsNothing);
    });

    group('with an action', () {
      late int undoCount;

      Future<void> pumpUndo(WidgetTester tester) => pumpShower(
        tester,
        (context) => foretackSnackBar(
          context,
          message: 'Verseny torolve',
          action: ForetackSnackBarAction(
            label: 'Visszavonas',
            onPressed: () => undoCount++,
          ),
          duration: const Duration(seconds: 5),
        ),
      );

      setUp(() => undoCount = 0);

      testWidgets('writes the action in upper case', (tester) async {
        // ACT
        await pumpUndo(tester);

        // ASSERT
        expect(find.text('VISSZAVONAS'), findsOneWidget);
      });

      testWidgets('runs the action once and closes on tap', (tester) async {
        // ARRANGE
        await pumpUndo(tester);

        // ACT — a masodik koppintas a bezaro animacio alatt jon.
        await tester.tap(find.text('VISSZAVONAS'));
        await tester.pump(const Duration(milliseconds: 50));
        // A cella a bezaro animacio alatt is koppinthato: a vedelem fut.
        expect(find.text('VISSZAVONAS').hitTestable(), findsOneWidget);
        await tester.tap(find.text('VISSZAVONAS'));
        await tester.pumpAndSettle();

        // ASSERT
        expect(undoCount, 1);
        expect(find.text('Verseny torolve'), findsNothing);
      });

      testWidgets('shrinks the countdown as the time runs out', (
        tester,
      ) async {
        // ARRANGE
        await pumpUndo(tester);
        final start = tester.widget<FractionallySizedBox>(countdownFill());

        // ACT — a 5 mp fele.
        await tester.pump(const Duration(milliseconds: 2500));

        // ASSERT
        final middle = tester.widget<FractionallySizedBox>(countdownFill());
        expect(start.widthFactor, greaterThan(0.9));
        expect(middle.widthFactor, closeTo(0.5, 0.1));
      });

      testWidgets('still closes on its own, without a tap', (tester) async {
        // ARRANGE
        await pumpUndo(tester);

        // ACT
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        // ASSERT
        expect(find.text('Verseny torolve'), findsNothing);
        expect(undoCount, 0);
      });
    });
  });
}
