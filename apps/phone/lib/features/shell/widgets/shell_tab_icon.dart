import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phone/features/shell/shell_tab.dart';

/// A sáv vonalikonja (makett 30a): 22 dp, 1,8-as vonal, szögletes végek.
///
/// A makett saját rajzai (zászló, mérőóra, óra); a Material-ikonok
/// kitöltött formái nem illenek a vonalas nyelvhez.
class ShellTabIcon extends StatelessWidget {
  /// A [tab] ikonja [color] színnel.
  const ShellTabIcon({required this.tab, required this.color, super.key});

  /// Az ikon mérete.
  static const double size = 22;

  /// Melyik fül ikonja.
  final ShellTab tab;

  /// A vonal színe.
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _ShellTabIconPainter(tab: tab, color: color),
    ),
  );
}

class _ShellTabIconPainter extends CustomPainter {
  _ShellTabIconPainter({required this.tab, required this.color});

  final ShellTab tab;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // A makett 22 × 22-es rácsán rajzolunk.
    canvas.scale(size.width / ShellTabIcon.size);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    switch (tab) {
      case ShellTab.races:
        canvas
          ..drawLine(const Offset(5, 3), const Offset(5, 20), paint)
          ..drawPath(
            Path()
              ..moveTo(5, 4)
              ..lineTo(17, 4)
              ..lineTo(14, 8)
              ..lineTo(17, 12)
              ..lineTo(5, 12),
            paint,
          );
      case ShellTab.instruments:
        canvas
          ..drawArc(
            Rect.fromCircle(center: const Offset(11, 16), radius: 8),
            math.pi,
            math.pi,
            false,
            paint,
          )
          ..drawLine(const Offset(11, 15), const Offset(15, 9), paint)
          ..drawLine(const Offset(3, 19.5), const Offset(19, 19.5), paint);
      case ShellTab.log:
        canvas
          ..drawCircle(const Offset(11, 11), 8, paint)
          ..drawPath(
            Path()
              ..moveTo(11, 6.5)
              ..lineTo(11, 11)
              ..lineTo(14.5, 13.5),
            paint,
          );
    }
  }

  @override
  bool shouldRepaint(_ShellTabIconPainter oldDelegate) =>
      oldDelegate.tab != tab || oldDelegate.color != color;
}
