import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/widgets/direction_arrow.dart';
import 'package:watch/widgets/watch_metrics.dart';

const _colors = WatchColors(
  background: Color(0xFF04080D),
  surface: Color(0xFF0D1822),
  text: Color(0xFFE9F1F7),
  textSecondary: Color(0xFF93A8BA),
  textTertiary: Color(0xFF5C7285),
  signal: Color(0xFF16E0C4),
  critical: Color(0xFFFF4D4D),
  port: Color(0xFFFF5A52),
  starboard: Color(0xFF2FD06E),
);

void main() {
  group('arrowColorForSide', () {
    test('maps side to the boat-side colour', () {
      expect(arrowColorForSide(ArrowSide.left, _colors), _colors.port);
      expect(arrowColorForSide(ArrowSide.right, _colors), _colors.starboard);
      expect(arrowColorForSide(ArrowSide.none, _colors), isNull);
    });
  });

  group('ArrowedValue', () {
    testWidgets('renders the value and a directional arrow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: ArrowedValue(
                value: '32°',
                side: ArrowSide.right,
                kind: ArrowKind.twa,
                colors: _colors,
                valueColor: Color(0xFFE9F1F7),
                fontSize: 24,
              ),
            ),
          ),
        ),
      );

      expect(find.text('32°'), findsOneWidget);
      expect(find.byType(DirectionArrow), findsOneWidget);
    });

    testWidgets('draws no arrow for ArrowSide.none', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: ArrowedValue(
                value: '0°',
                side: ArrowSide.none,
                kind: ArrowKind.twa,
                colors: _colors,
                valueColor: Color(0xFFE9F1F7),
                fontSize: 24,
              ),
            ),
          ),
        ),
      );

      expect(find.text('0°'), findsOneWidget);
      expect(find.byType(DirectionArrow), findsNothing);
    });

    testWidgets('renders only the arrow when the value is empty', (
      tester,
    ) async {
      // Korrekció-eset: csak a kifelé mutató nyíl, szöveg nélkül.
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: ArrowedValue(
                value: '',
                side: ArrowSide.left,
                kind: ArrowKind.correction,
                colors: _colors,
                valueColor: Color(0xFFE9F1F7),
                fontSize: 24,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DirectionArrow), findsOneWidget);
    });
  });

  group('WatchMetricCell', () {
    testWidgets('renders the label and the value widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: WatchMetricCell(
                label: 'ETA',
                value: Text('07:32'),
                colors: _colors,
              ),
            ),
          ),
        ),
      );

      expect(find.text('ETA'), findsOneWidget);
      expect(find.text('07:32'), findsOneWidget);
    });
  });
}
