import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/season_stats/medal.dart';

/// A [medal] érem színe a téma `MedalColors`-ából.
Color medalColorOf(MedalColors colors, Medal medal) => switch (medal) {
  Medal.gold => colors.gold,
  Medal.silver => colors.silver,
  Medal.bronze => colors.bronze,
};

/// Egy vitorla-jel: kitöltve az érem színével, vagy üres körvonal a
/// dobogó nélküli versenyre (ADR 0049 Addendum 2 R6).
///
/// A `MedalColors` és a `TextTones` biztonságos: a `foretackTheme`
/// regisztrálja.
class SailMark extends StatelessWidget {
  /// Vitorla [width] szélességgel; a magasság a 11×15-ös rács aránya.
  const SailMark({required this.medal, required this.width, super.key});

  /// Az érem; `null` az üres vitorla.
  final Medal? medal;

  /// A jel szélessége logikai pixelben.
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = this.medal;
    return CustomPaint(
      size: Size(width, width * _SailPainter.heightPerWidth),
      painter: _SailPainter(
        color: medal == null
            ? theme.extension<TextTones>()!.low
            : medalColorOf(theme.extension<MedalColors>()!, medal),
        isFilled: medal != null,
      ),
    );
  }
}

class _SailPainter extends CustomPainter {
  const _SailPainter({required this.color, required this.isFilled});

  // A makett rácsa (15a): a vitorla egy 11×15-ös négyzetben áll.
  static const double gridWidth = 11;
  static const double gridHeight = 15;
  static const double heightPerWidth = gridHeight / gridWidth;

  final Color color;
  final bool isFilled;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / gridWidth;
    canvas.scale(scale);
    final path = Path()
      ..moveTo(1, 0.5)
      ..lineTo(1, 14.5)
      ..lineTo(10.5, 14.5)
      ..quadraticBezierTo(9, 5.5, 1, 0.5)
      ..close();
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      // A körvonal a képernyőn 1,1 px, a jel méretétől függetlenül.
      ..strokeWidth = 1.1 / scale;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SailPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isFilled != isFilled;
}
