import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/marine_colors.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/live_race/widgets/confidence_dots.dart';
import 'package:phone/features/live_race/widgets/correction_value.dart';
import 'package:phone/features/live_race/widgets/side_arrow.dart';
import 'package:phone/features/live_race/widgets/twa_value.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: foretackTheme,
    home: Scaffold(body: child),
  ),
);

Finder _arrowPaint() => find.descendant(
  of: find.byType(SideArrow),
  matching: find.byType(CustomPaint),
);

ArrowPainter _painterOf(WidgetTester tester) {
  // A SideArrow csak nem-none oldalnal rajzol, es kizarolag ArrowPainter-t;
  // a hivo teszt eppen azt az agat pumpolja.
  return tester.widget<CustomPaint>(_arrowPaint()).painter! as ArrowPainter;
}

void main() {
  group('TwaValue', () {
    testWidgets('starboard: number, inward solid arrow, green', (
      tester,
    ) async {
      await _pump(
        tester,
        const TwaValue(Angle(degrees: 32), style: numeralMediumStyle),
      );

      expect(find.text('32°'), findsOneWidget);
      final painter = _painterOf(tester);
      expect(painter.color, starboardColor);
      expect(painter.isSolid, isTrue);
      expect(painter.pointsLeft, isTrue);
    });

    testWidgets('port: inward solid arrow, red', (tester) async {
      await _pump(
        tester,
        const TwaValue(Angle(degrees: -47), style: numeralMediumStyle),
      );

      expect(find.text('47°'), findsOneWidget);
      final painter = _painterOf(tester);
      expect(painter.color, portColor);
      expect(painter.pointsLeft, isFalse);
    });

    testWidgets('zero: no arrow', (tester) async {
      await _pump(
        tester,
        const TwaValue(Angle(degrees: 0), style: numeralMediumStyle),
      );

      expect(find.text('0°'), findsOneWidget);
      expect(_arrowPaint(), findsNothing);
    });

    testWidgets('null: placeholder, no arrow', (tester) async {
      await _pump(tester, const TwaValue(null, style: numeralMediumStyle));

      expect(find.text('—'), findsOneWidget);
      expect(_arrowPaint(), findsNothing);
    });
  });

  group('CorrectionValue', () {
    testWidgets('right: outward line arrow, green', (tester) async {
      await _pump(
        tester,
        const CorrectionValue(Angle(degrees: 8), style: numeralLargeStyle),
      );

      expect(find.text('8°'), findsOneWidget);
      final painter = _painterOf(tester);
      expect(painter.color, starboardColor);
      expect(painter.isSolid, isFalse);
      // A kormany-nyil kifele mutat: a jobb oldali jobbra.
      expect(painter.pointsLeft, isFalse);
    });

    testWidgets('left: outward line arrow, red', (tester) async {
      await _pump(
        tester,
        const CorrectionValue(Angle(degrees: -8), style: numeralLargeStyle),
      );

      expect(find.text('8°'), findsOneWidget);
      final painter = _painterOf(tester);
      expect(painter.color, portColor);
      expect(painter.pointsLeft, isTrue);
    });
  });

  group('ConfidenceDots', () {
    testWidgets('medium fills two of three dots', (tester) async {
      await _pump(tester, const ConfidenceDots(WindShiftConfidence.medium));

      expect(find.byIcon(Icons.circle), findsNWidgets(2));
      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    });
  });
}
