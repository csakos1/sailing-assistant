import 'package:flutter/rendering.dart';
import 'package:foretack_web/auth/sign_in/qr_module_layout.dart';
import 'package:qr/qr.dart';

/// Egy kódolt QR-kép rajzolója (ADR 0051 Addendum 7 P1, P6).
///
/// A teljes felületet a [light] alapszínnel tölti ki (ez a csendes zóna
/// is), a sötét modulokat a [dark] színnel, egész pixeles rácsra. Az
/// élsimítás ki van kapcsolva, hogy a modulok határa éles maradjon.
class QrCodePainter extends CustomPainter {
  /// Rajzoló az [image] képhez, legalább [quietZone] csendes zónával.
  QrCodePainter({
    required this.image,
    required this.light,
    required this.dark,
    required this.quietZone,
  });

  /// A kódolt kép.
  final QrImage image;

  /// Az alap és a csendes zóna színe.
  final Color light;

  /// A sötét modulok színe.
  final Color dark;

  /// A csendes zóna legkisebb szélessége.
  final double quietZone;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = light);
    final layout = qrModuleLayout(
      extent: size.shortestSide,
      moduleCount: image.moduleCount,
      quietZone: quietZone,
    );
    final module = layout.moduleSize;
    final modulePaint = Paint()
      ..color = dark
      ..isAntiAlias = false;
    for (var row = 0; row < image.moduleCount; row++) {
      for (var column = 0; column < image.moduleCount; column++) {
        if (!image.isDark(row, column)) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            layout.offset + column * module,
            layout.offset + row * module,
            module,
            module,
          ),
          modulePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(QrCodePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.light != light ||
      oldDelegate.dark != dark ||
      oldDelegate.quietZone != quietZone;
}
