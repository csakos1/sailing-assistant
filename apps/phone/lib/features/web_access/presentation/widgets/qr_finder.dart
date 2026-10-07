import 'package:flutter/material.dart';

/// A beolvasó 260 px-es keresője: négy sarokjel (makett 18b).
///
/// Hibapanel alatt 35%-ra halványul (18d-2), így látszik, hogy a kép
/// megállt.
class QrFinder extends StatelessWidget {
  /// Kereső; [isDimmed] esetén halvány.
  const QrFinder({required this.isDimmed, super.key});

  /// A kereső mérete.
  static const double size = 260;

  /// Halvány-e (hibapanel alatt).
  final bool isDimmed;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Opacity(
      opacity: isDimmed ? 0.35 : 1,
      child: CustomPaint(
        painter: _CornerPainter(color),
        child: const SizedBox.square(dimension: size),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter(this.color);

  final Color color;

  static const double _arm = 24;
  static const double _stroke = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _stroke
      ..style = PaintingStyle.stroke;
    final right = size.width;
    final bottom = size.height;
    final corners = [
      [const Offset(0, _arm), Offset.zero, const Offset(_arm, 0)],
      [Offset(right - _arm, 0), Offset(right, 0), Offset(right, _arm)],
      [Offset(0, bottom - _arm), Offset(0, bottom), Offset(_arm, bottom)],
      [
        Offset(right - _arm, bottom),
        Offset(right, bottom),
        Offset(right, bottom - _arm),
      ],
    ];
    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[1].dx, corner[1].dy)
        ..lineTo(corner[2].dx, corner[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => oldDelegate.color != color;
}
