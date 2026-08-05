import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_detail/track_stats_formatters.dart';
import 'package:phone/features/race_log/race_log_formatters.dart';
import 'package:phone/features/race_log/widgets/race_log_stats_strip.dart';

void main() {
  Future<void> pumpStrip(
    WidgetTester tester, {
    required List<RaceLogStatCell> cells,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        home: Scaffold(
          body: RaceLogStatsStrip(cells: cells),
        ),
      ),
    );
  }

  group('RaceLogStatsStrip', () {
    testWidgets('renders every label with its value and unit', (tester) async {
      await pumpStrip(
        tester,
        cells: [
          (
            label: 'VIZEN TOLTOTT',
            measured: measureHours(const Duration(hours: 42, minutes: 20)),
          ),
          (label: 'OSSZ. TAV', measured: measureDistance(24600)),
          (label: 'REKORD', measured: measureKnots(6.2)),
        ],
      );

      expect(find.text('VIZEN TOLTOTT'), findsOneWidget);
      expect(find.text('42,3'), findsOneWidget);
      expect(find.text('ó'), findsOneWidget);
      expect(find.text('24,6'), findsOneWidget);
      expect(find.text('km'), findsOneWidget);
      expect(find.text('12,1'), findsOneWidget);
      expect(find.text('kn'), findsOneWidget);
    });

    testWidgets('drops the unit next to a missing value', (tester) async {
      await pumpStrip(
        tester,
        cells: [
          (label: 'OSSZ. TAV', measured: measureDistance(null)),
        ],
      );

      expect(find.text('—'), findsOneWidget);
      expect(find.text('km'), findsNothing);
      expect(find.text('m'), findsNothing);
    });

    testWidgets('draws a hairline around and between the cells', (
      tester,
    ) async {
      // Ket vizszintes vonal, plusz cellakozonkent egy fuggoleges.
      await pumpStrip(
        tester,
        cells: [
          (label: 'A', measured: measureDistance(1200)),
          (label: 'B', measured: measureDistance(2400)),
          (label: 'C', measured: measureDistance(3600)),
        ],
      );

      expect(
        find.descendant(
          of: find.byType(RaceLogStatsStrip),
          matching: find.byType(ColoredBox),
        ),
        findsNWidgets(4),
      );
    });

    testWidgets('gives the cells equal width', (tester) async {
      await pumpStrip(
        tester,
        cells: [
          (label: 'A', measured: measureDistance(1200)),
          (label: 'B', measured: measureDistance(2400)),
        ],
      );

      // Ket egyenlo cellanal a bal el es az elso felirat kozepe kozotti
      // tavolsag megegyezik a masodik kozepe es a jobb el kozottivel.
      final width = tester.getSize(find.byType(RaceLogStatsStrip)).width;
      final first = tester.getCenter(find.text('A')).dx;
      final second = tester.getCenter(find.text('B')).dx;

      expect(first, moreOrLessEquals(width - second, epsilon: 0.5));
    });
  });
}
