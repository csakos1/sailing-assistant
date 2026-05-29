import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/marine_colors.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/live_race/widgets/confidence_dots.dart';
import 'package:phone/features/live_race/widgets/correction_value.dart';
import 'package:phone/features/live_race/widgets/metric_cell.dart';
import 'package:phone/features/live_race/widgets/metric_value_text.dart';
import 'package:phone/features/live_race/widgets/twa_value.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: foretackTheme,
    home: Scaffold(body: child),
  ),
);

Color? _iconColor(WidgetTester tester, IconData icon) =>
    tester.widget<Icon>(find.byIcon(icon)).color;

void main() {
  group('TwaValue', () {
    testWidgets('starboard: number, inward arrow on the right, green', (
      tester,
    ) async {
      await _pump(tester, const TwaValue(Angle(degrees: 32)));

      expect(find.text('32°'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_left), findsOneWidget);
      expect(_iconColor(tester, Icons.arrow_left), starboardColor);
    });

    testWidgets('port: inward arrow on the left, red', (tester) async {
      await _pump(tester, const TwaValue(Angle(degrees: -47)));

      expect(find.text('47°'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_right), findsOneWidget);
      expect(_iconColor(tester, Icons.arrow_right), portColor);
    });

    testWidgets('zero: no arrow', (tester) async {
      await _pump(tester, const TwaValue(Angle(degrees: 0)));

      expect(find.text('0°'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('null: placeholder, no arrow', (tester) async {
      await _pump(tester, const TwaValue(null));

      expect(find.text('—'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });
  });

  group('CorrectionValue', () {
    testWidgets('right: outward arrow on the right, green', (tester) async {
      await _pump(tester, const CorrectionValue(Angle(degrees: 8)));

      expect(find.text('8°'), findsOneWidget);
      expect(find.byIcon(Icons.east), findsOneWidget);
      expect(_iconColor(tester, Icons.east), starboardColor);
    });

    testWidgets('left: outward arrow on the left, red', (tester) async {
      await _pump(tester, const CorrectionValue(Angle(degrees: -8)));

      expect(find.text('8°'), findsOneWidget);
      expect(find.byIcon(Icons.west), findsOneWidget);
      expect(_iconColor(tester, Icons.west), portColor);
    });
  });

  group('ConfidenceDots', () {
    testWidgets('medium fills two of three dots', (tester) async {
      await _pump(tester, const ConfidenceDots(WindShiftConfidence.medium));

      expect(find.byIcon(Icons.circle), findsNWidgets(2));
      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    });
  });

  group('MetricCell + MetricValueText', () {
    testWidgets('renders the label and the value child', (tester) async {
      await _pump(
        tester,
        const MetricCell(label: 'TWA most', child: MetricValueText('095°')),
      );

      expect(find.text('TWA most'), findsOneWidget);
      expect(find.text('095°'), findsOneWidget);
    });
  });
}
