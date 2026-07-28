import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/live_race/widgets/data_rail.dart';
import 'package:phone/features/live_race/widgets/main_column_cell.dart';
import 'package:phone/features/live_race/widgets/rail_cell.dart';

// A cellak a szulo flexebol kapjak a magassagot, ezert kotott dobozba
// tesszuk oket; a sin szelesseget viszont a DataRail maga adja.
Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: foretackTheme,
    home: Scaffold(body: SizedBox(height: 300, child: child)),
  ),
);

BoxDecoration _decorationOf(WidgetTester tester, Type ancestor) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(ancestor),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return box.decoration as BoxDecoration;
}

void main() {
  group('MainColumnCell', () {
    testWidgets('renders the label, the value and the trailing widget', (
      tester,
    ) async {
      await _pump(
        tester,
        const MainColumnCell(
          label: 'TWA KOV.',
          trailing: Text('dots'),
          child: Text('51'),
        ),
      );

      expect(find.text('TWA KOV.'), findsOneWidget);
      expect(find.text('51'), findsOneWidget);
      expect(find.text('dots'), findsOneWidget);
    });

    testWidgets('scales the value down inside its own cell', (tester) async {
      await _pump(
        tester,
        const MainColumnCell(label: 'TWA KOV.', child: Text('51')),
      );

      final fitted = tester.widget<FittedBox>(
        find.descendant(
          of: find.byType(MainColumnCell),
          matching: find.byType(FittedBox),
        ),
      );
      expect(fitted.fit, BoxFit.scaleDown);
    });
  });

  group('RailCell', () {
    testWidgets('renders the label and the value', (tester) async {
      await _pump(tester, const RailCell(label: 'BEARING', value: '095'));

      expect(find.text('BEARING'), findsOneWidget);
      expect(find.text('095'), findsOneWidget);
    });

    testWidgets('omits the support row when there is no support text', (
      tester,
    ) async {
      await _pump(tester, const RailCell(label: 'VMG', value: '5,8'));

      expect(
        find.descendant(
          of: find.byType(RailCell),
          matching: find.byType(Row),
        ),
        findsNothing,
      );
    });

    testWidgets('renders the support text next to its arrow', (tester) async {
      await _pump(
        tester,
        const RailCell(
          label: 'VMG',
          value: '5,8',
          support: 'cel 6,2',
          supportArrow: Text('arrow'),
        ),
      );

      expect(find.text('cel 6,2'), findsOneWidget);
      expect(find.text('arrow'), findsOneWidget);
    });

    testWidgets('drops the divider on the last cell of the rail', (
      tester,
    ) async {
      await _pump(
        tester,
        const RailCell(label: 'VMG', value: '5,8', hasDivider: false),
      );

      expect(_decorationOf(tester, RailCell).border, isNull);
    });

    testWidgets('draws a divider by default', (tester) async {
      await _pump(tester, const RailCell(label: 'ETA', value: '07:32'));

      expect(_decorationOf(tester, RailCell).border, isNotNull);
    });
  });

  group('DataRail', () {
    testWidgets('is 132 dp wide by default', (tester) async {
      await _pump(
        tester,
        const DataRail(cells: [SizedBox(), SizedBox(), SizedBox()]),
      );

      expect(tester.getSize(find.byType(DataRail)).width, 132);
    });

    testWidgets('gives every cell the same flex', (tester) async {
      await _pump(
        tester,
        const DataRail(cells: [SizedBox(), SizedBox(), SizedBox()]),
      );

      final flexes = tester
          .widgetList<Expanded>(
            find.descendant(
              of: find.byType(DataRail),
              matching: find.byType(Expanded),
            ),
          )
          .map((expanded) => expanded.flex)
          .toList();
      expect(flexes, [1, 1, 1]);
    });

    // Regresszio-or: stretch nelkul a cellak a tartalmukra zsugorodnak, es
    // a cella-hatarok nem ernek el a sin szeleig.
    testWidgets('stretches every cell to the full rail width', (tester) async {
      await _pump(
        tester,
        const DataRail(
          cells: [
            RailCell(label: 'BEARING', value: '232°'),
            RailCell(label: 'ETA', value: '128 perc'),
          ],
        ),
      );

      // A sin bal szeli hairline-ja a BoxDecoration Border-je, ami a
      // dobozon BELUL rajzolodik: a cellak a 132 dp-bol 131-et kapnak.
      expect(tester.getSize(find.byType(RailCell).first).width, 131);
      expect(tester.getSize(find.byType(RailCell).last).width, 131);
    });
  });
}
