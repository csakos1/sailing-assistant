import 'package:flutter/material.dart';
import 'package:foretack_web/auth/sign_in/qr_code_painter.dart';
import 'package:qr/qr.dart';

/// A belépési QR-kód képe (ADR 0051 Addendum 7 P6, Addendum 1 H12).
///
/// 264 px-es mező `onSurface` alapon, `surface` modulokkal, legalább
/// 16 px-es csendes zónával. A kódolás drága (maszk-választás), ezért a
/// kép csak a szöveg változásakor készül újra, nem minden másodperces
/// frissítésnél.
class QrCodeImage extends StatefulWidget {
  /// A [text] kódja, a képernyőolvasónak a [semanticLabel] címkével.
  const QrCodeImage({
    required this.text,
    required this.semanticLabel,
    super.key,
  });

  /// A mező oldala.
  static const double extent = 264;

  /// A csendes zóna legkisebb szélessége.
  static const double quietZone = 16;

  /// A kódolt szöveg (`foretack-login:v1:…`).
  final String text;

  /// A képernyőolvasó címkéje.
  final String semanticLabel;

  @override
  State<QrCodeImage> createState() => _QrCodeImageState();
}

class _QrCodeImageState extends State<QrCodeImage> {
  late QrImage _image = _encode(widget.text);

  @override
  void didUpdateWidget(QrCodeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _image = _encode(widget.text);
  }

  // A `QrCode` alapból közepes (~15%) hibajavítást használ (P6).
  static QrImage _encode(String text) =>
      QrImage(QrCode(payload: QrPayload.fromString(text)));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: CustomPaint(
        size: const Size.square(QrCodeImage.extent),
        painter: QrCodePainter(
          image: _image,
          light: scheme.onSurface,
          dark: scheme.surface,
          quietZone: QrCodeImage.quietZone,
        ),
      ),
    );
  }
}
