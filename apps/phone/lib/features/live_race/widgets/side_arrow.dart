import 'package:flutter/material.dart';
import 'package:phone/app/marine_colors.dart';
import 'package:phone/features/live_race/live_formatters.dart';

/// A nyíl rajzolatának stílusa (ADR 0042 D7).
///
/// A két stílus **nem** a színben tér el, hanem a rajzolatban: a szín az
/// oldalt kódolja (jobb → zöld, bal → piros), a stílus a jelentést.
enum ArrowGlyph {
  /// Tömör háromszög — a TWA oldal-nyila, a szám felé (befelé) mutat.
  solid,

  /// Vonal-nyíl — a kormány-korrekció, a fordulás felé (kifelé) mutat.
  line,
}

/// Egy oldal-nyíl a v1 Material ikonjai helyett (ADR 0042 D7).
///
/// A [size] a befoglaló négyzet oldala: a nyíl mérete a kísérő szám
/// stílusából származik, nem konstans, hogy a 76 / 48 / 38 / 20 pt-os
/// helyeken arányos maradjon. [ArrowSide.none] esetén nem rajzol semmit —
/// a szélbe álló hajónak és a nulla korrekciónak nincs oldala.
///
/// Az irányt a [side] és a [glyph] **együtt** adja: a tömör háromszög
/// befelé mutat (a jobb oldali balra), a vonal-nyíl kifelé (a jobb oldali
/// jobbra). A leképezést az [ArrowPainter] hordozza, hogy tesztelhető
/// legyen.
class SideArrow extends StatelessWidget {
  /// Egy oldal-nyíl.
  const SideArrow({
    required this.side,
    required this.glyph,
    required this.size,
    super.key,
  });

  /// Melyik oldalt kódolja; ebből jön a szín és az irány fele.
  final ArrowSide side;

  /// A rajzolat stílusa; ebből jön az irány másik fele.
  final ArrowGlyph glyph;

  /// A befoglaló négyzet oldala logikai pixelben.
  final double size;

  @override
  Widget build(BuildContext context) {
    if (side == ArrowSide.none) {
      return const SizedBox.shrink();
    }
    final pointsLeft = glyph == ArrowGlyph.solid
        ? side == ArrowSide.right
        : side == ArrowSide.left;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ArrowPainter(
          color: side == ArrowSide.right ? starboardColor : portColor,
          pointsLeft: pointsLeft,
          isSolid: glyph == ArrowGlyph.solid,
        ),
      ),
    );
  }
}

/// A [SideArrow] festője.
///
/// Publikus osztály, hogy az oldal → szín + irány leképezés widget-tesztben
/// ellenőrizhető legyen; a [SideArrow] a fába csak ezt teszi be.
class ArrowPainter extends CustomPainter {
  /// A festő bemenetei.
  const ArrowPainter({
    required this.color,
    required this.pointsLeft,
    required this.isSolid,
  });

  /// A nyíl színe: starboard zöld vagy port piros.
  final Color color;

  /// Igaz, ha a nyíl hegye balra néz.
  final bool pointsLeft;

  /// Igaz a tömör háromszögnél, hamis a vonal-nyílnál.
  final bool isSolid;

  @override
  void paint(Canvas canvas, Size size) {
    // A rajz mindig balra mutatva készül; a jobbra mutatáshoz a vásznat
    // tükrözzük, így a két irány geometriája garantáltan azonos.
    canvas.save();
    if (!pointsLeft) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    if (isSolid) {
      _paintTriangle(canvas, size);
    } else {
      _paintLineArrow(canvas, size);
    }
    canvas.restore();
  }

  // Tömör háromszög: a csúcs a bal oldal közepén, az alap a jobb szélen.
  // A behúzás optikai: teli magasságnál a háromszög tömegesebbnek látszik,
  // mint a mellette álló szám.
  void _paintTriangle(Canvas canvas, Size size) {
    final inset = size.height * 0.12;
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, inset)
      ..lineTo(size.width, size.height - inset)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  // Vonal-nyíl: vízszintes szár + két fej-vonás. A vonalvastagság a mérethez
  // kötött (~2,4 dp a 48 pt-os cellában), hogy a tömör háromszögtől
  // ránézésre elkülönüljön.
  void _paintLineArrow(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final middle = size.height / 2;
    final head = size.height * 0.3;
    canvas
      ..drawLine(Offset(0, middle), Offset(size.width, middle), stroke)
      ..drawPath(
        Path()
          ..moveTo(head, middle - head)
          ..lineTo(0, middle)
          ..lineTo(head, middle + head),
        stroke,
      );
  }

  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.pointsLeft != pointsLeft ||
      oldDelegate.isSolid != isSolid;
}
