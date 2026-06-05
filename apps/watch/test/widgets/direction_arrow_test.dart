import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:watch/widgets/direction_arrow.dart';

void main() {
  group('arrowPointsRight', () {
    test('TWA points inward toward the number', () {
      // stbd a szám jobbján → befelé = balra; port a balján → befelé = jobbra.
      expect(arrowPointsRight(ArrowSide.right, ArrowKind.twa), isFalse);
      expect(arrowPointsRight(ArrowSide.left, ArrowKind.twa), isTrue);
    });

    test('correction points outward toward the turn', () {
      // jobbra fordulj → jobbra; balra fordulj → balra.
      expect(arrowPointsRight(ArrowSide.right, ArrowKind.correction), isTrue);
      expect(arrowPointsRight(ArrowSide.left, ArrowKind.correction), isFalse);
    });
  });

  group('DirectionArrow', () {
    testWidgets('renders a CustomPaint for both kinds', (tester) async {
      await tester.pumpWidget(
        const Center(
          child: DirectionArrow.twa(
            side: ArrowSide.right,
            color: Color(0xFF2FD06E),
          ),
        ),
      );
      expect(find.byType(DirectionArrow), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      await tester.pumpWidget(
        const Center(
          child: DirectionArrow.correction(
            side: ArrowSide.left,
            color: Color(0xFFFF5A52),
          ),
        ),
      );
      expect(find.byType(DirectionArrow), findsOneWidget);
    });

    testWidgets('draws nothing for ArrowSide.none without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Center(
          child: DirectionArrow.twa(
            side: ArrowSide.none,
            color: Color(0xFF2FD06E),
          ),
        ),
      );

      expect(find.byType(DirectionArrow), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
