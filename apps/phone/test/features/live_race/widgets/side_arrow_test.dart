import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/marine_colors.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/live_race/live_formatters.dart';
import 'package:phone/features/live_race/widgets/side_arrow.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: foretackTheme,
    home: Scaffold(body: child),
  ),
);

Finder _paintFinder() => find.descendant(
  of: find.byType(SideArrow),
  matching: find.byType(CustomPaint),
);

ArrowPainter _painterOf(WidgetTester tester) {
  // A SideArrow minden nem-none oldalnal allit painter-t, es kizarolag
  // ArrowPainter-t; a hivo teszt eppen ezt az agat pumpolja.
  return tester.widget<CustomPaint>(_paintFinder()).painter! as ArrowPainter;
}

void main() {
  group('SideArrow', () {
    testWidgets('solid glyph on the starboard side points inward, green', (
      tester,
    ) async {
      await _pump(
        tester,
        const SideArrow(
          side: ArrowSide.right,
          glyph: ArrowGlyph.solid,
          size: 24,
        ),
      );

      final painter = _painterOf(tester);
      expect(painter.color, starboardColor);
      expect(painter.isSolid, isTrue);
      // Jobb oldalt allo tomor haromszog befele = balra mutat.
      expect(painter.pointsLeft, isTrue);
    });

    testWidgets('solid glyph on the port side points inward, red', (
      tester,
    ) async {
      await _pump(
        tester,
        const SideArrow(
          side: ArrowSide.left,
          glyph: ArrowGlyph.solid,
          size: 24,
        ),
      );

      final painter = _painterOf(tester);
      expect(painter.color, portColor);
      expect(painter.pointsLeft, isFalse);
    });

    testWidgets('line glyph on the starboard side points outward', (
      tester,
    ) async {
      await _pump(
        tester,
        const SideArrow(
          side: ArrowSide.right,
          glyph: ArrowGlyph.line,
          size: 24,
        ),
      );

      final painter = _painterOf(tester);
      expect(painter.color, starboardColor);
      expect(painter.isSolid, isFalse);
      // Kormany-nyil kifele: a jobb oldali jobbra mutat.
      expect(painter.pointsLeft, isFalse);
    });

    testWidgets('line glyph on the port side points outward', (tester) async {
      await _pump(
        tester,
        const SideArrow(
          side: ArrowSide.left,
          glyph: ArrowGlyph.line,
          size: 24,
        ),
      );

      final painter = _painterOf(tester);
      expect(painter.color, portColor);
      expect(painter.pointsLeft, isTrue);
    });

    testWidgets('paints nothing when there is no side', (tester) async {
      await _pump(
        tester,
        const SideArrow(
          side: ArrowSide.none,
          glyph: ArrowGlyph.solid,
          size: 24,
        ),
      );

      expect(_paintFinder(), findsNothing);
    });
  });

  group('ArrowPainter', () {
    const painter = ArrowPainter(
      color: starboardColor,
      pointsLeft: true,
      isSolid: true,
    );

    test('does not repaint for identical inputs', () {
      expect(
        painter.shouldRepaint(
          const ArrowPainter(
            color: starboardColor,
            pointsLeft: true,
            isSolid: true,
          ),
        ),
        isFalse,
      );
    });

    test('repaints when the direction or the glyph changes', () {
      expect(
        painter.shouldRepaint(
          const ArrowPainter(
            color: starboardColor,
            pointsLeft: false,
            isSolid: true,
          ),
        ),
        isTrue,
      );
      expect(
        painter.shouldRepaint(
          const ArrowPainter(
            color: starboardColor,
            pointsLeft: true,
            isSolid: false,
          ),
        ),
        isTrue,
      );
    });
  });
}
