import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// A nyíl fajtája — a glyph-stílust és a mutatás irányát együtt rögzíti, hogy
/// érvénytelen kombináció (pl. tömör háromszög kifelé) ne legyen ábrázolható.
enum ArrowKind {
  /// TWA-nyíl: tömör háromszög, a szám felé (befelé) — a szél érkezési oldala.
  twa,

  /// Korrekció-nyíl: vonal-nyíl, a fordulás irányába (kifelé).
  correction,
}

/// Igaz, ha a [side]/[kind] párosnál a nyíl jobbra mutat (különben balra).
///
/// A TWA befelé mutat (a szám felé): stbd (jobb oldal) → balra, port (bal
/// oldal) → jobbra. A korrekció kifelé (a fordulás felé): jobb → jobbra, bal →
/// balra. `none` esetén nem rajzolunk; a visszatérés determinisztikus.
bool arrowPointsRight(ArrowSide side, ArrowKind kind) => switch (kind) {
  ArrowKind.twa => side == ArrowSide.left,
  ArrowKind.correction => side == ArrowSide.right,
};

/// Irány-nyíl glyph az óra-nézetekhez (ADR 0015, watch-ui-ux.md konvenció).
///
/// A nyíl OLDALÁT a hívó az `arrowSideFromSign`-ból kapott [side]-dal adja meg,
/// a SZÍNÉT a hajós konvencióval ([color]: stbd zöld / port piros). A glyph
/// stílusát és irányát a konstruktor választja: [DirectionArrow.twa] tömör
/// háromszög befelé, [DirectionArrow.correction] vonal-nyíl kifelé.
/// `ArrowSide.none` esetén semmit sem rajzol. A bal/jobb elhelyezés a számhoz
/// képest a nézet dolga.
class DirectionArrow extends StatelessWidget {
  /// TWA-nyíl: tömör háromszög a szám felé (befelé).
  const DirectionArrow.twa({
    required this.side,
    required this.color,
    this.size = 18,
    super.key,
  }) : _kind = ArrowKind.twa;

  /// Korrekció-nyíl: vonal-nyíl a fordulás irányába (kifelé).
  const DirectionArrow.correction({
    required this.side,
    required this.color,
    this.size = 18,
    super.key,
  }) : _kind = ArrowKind.correction;

  /// A nyíl oldala (`arrowSideFromSign`-ból): bal / jobb / nincs.
  final ArrowSide side;

  /// A nyíl színe (hajós konvenció: stbd zöld, port piros).
  final Color color;

  /// A négyzetes glyph oldalhossza logikai pixelben.
  final double size;

  final ArrowKind _kind;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ArrowPainter(side: side, kind: _kind, color: color),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({
    required this.side,
    required this.kind,
    required this.color,
  });

  final ArrowSide side;
  final ArrowKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (side == ArrowSide.none) {
      return; // szélbe / nincs adat → nincs nyíl
    }
    final pointsRight = arrowPointsRight(side, kind);
    switch (kind) {
      case ArrowKind.twa:
        _paintTriangle(canvas, size, pointsRight: pointsRight);
      case ArrowKind.correction:
        _paintLineArrow(canvas, size, pointsRight: pointsRight);
    }
  }

  void _paintTriangle(Canvas canvas, Size size, {required bool pointsRight}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final path = Path();
    if (pointsRight) {
      path
        ..moveTo(0, 0)
        ..lineTo(0, h)
        ..lineTo(w, h / 2)
        ..close();
    } else {
      path
        ..moveTo(w, 0)
        ..lineTo(w, h)
        ..lineTo(0, h / 2)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  void _paintLineArrow(Canvas canvas, Size size, {required bool pointsRight}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final midY = size.height / 2;
    final head = size.shortestSide * 0.4;
    final path = Path();
    if (pointsRight) {
      path
        ..moveTo(0, midY)
        ..lineTo(w, midY)
        ..moveTo(w - head, midY - head)
        ..lineTo(w, midY)
        ..lineTo(w - head, midY + head);
    } else {
      path
        ..moveTo(w, midY)
        ..lineTo(0, midY)
        ..moveTo(head, midY - head)
        ..lineTo(0, midY)
        ..lineTo(head, midY + head);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.side != side ||
      oldDelegate.kind != kind ||
      oldDelegate.color != color;
}
