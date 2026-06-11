import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Jobb perem-ív a predikció-konfidenciához (ADR 0023 D7, jobb-perem revízió):
/// a kerek lap **JOBB** peremén egy ív, aminek a [color]-a és a [fraction]-je
/// (hossza) a shiftConfidence-szintet kódolja. A jobb perem a felső GPS-idő
/// fejléctől és az alsó lap-pöttyöktől is szabad. A `RaceShell` a teljes
/// képernyős háttér-rétegben rajzolja, ezért a fizikai lap peremén ül — minden
/// óra-méreten és ambientben is. Ambientben halványabb és vékonyabb (a ±° szám
/// viszi a trust-et, D8).
///
/// A festő (`_ConfidenceArcPainter`) privát; a widget a tesztelhető felület
/// (a teszt a [color]/[fraction] mezőkre asszertál, nem pixelre).
class ConfidenceArc extends StatelessWidget {
  /// Létrehozza az ívet a [color] színnel és a [fraction] (0..1) hosszal.
  const ConfidenceArc({
    required this.color,
    required this.fraction,
    this.ambient = false,
    super.key,
  });

  /// Az ív színe (a shiftConfidence-szint színe).
  final Color color;

  /// Az ív hossza a maximális szögnyíláshoz viszonyítva (0..1).
  final double fraction;

  /// Ambient mód: halványabb, vékonyabb ív.
  final bool ambient;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ConfidenceArcPainter(
        color: color,
        fraction: fraction,
        ambient: ambient,
      ),
    );
  }
}

class _ConfidenceArcPainter extends CustomPainter {
  _ConfidenceArcPainter({
    required this.color,
    required this.fraction,
    required this.ambient,
  });

  final Color color;
  final double fraction;
  final bool ambient;

  /// A teljes (high) ív szögnyílása radiánban (~84°).
  static const double _maxSweepRad = 84 * math.pi / 180;

  /// Az ív behúzása a lap pereméhez képest, pixelben.
  static const double _inset = 6;

  /// Az ív vastagsága aktívban (ambientben −1).
  static const double _strokeWidth = 4;

  @override
  void paint(Canvas canvas, Size size) {
    if (fraction <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - _inset;
    final sweep = _maxSweepRad * fraction.clamp(0, 1);

    // A lap jobb peremére centráljuk: jobbra = 0 (canvas-szög, 0 = 3 óra), a
    // sweep felét fölé, felét alá nyitva.
    final start = -sweep / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ambient ? _strokeWidth - 1 : _strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = ambient ? color.withValues(alpha: 0.4) : color;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ConfidenceArcPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.fraction != fraction ||
      oldDelegate.ambient != ambient;
}
