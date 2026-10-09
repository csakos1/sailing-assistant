import 'dart:async';

import 'package:flutter/widgets.dart';

/// A QR cseréje (17b, ADR 0051 Addendum 1 H10): az új kód 240 ms alatt
/// felülről lefelé söpör a régi fölé, a régi közben 30%-on látszik.
class QrReveal extends StatefulWidget {
  /// Csere a [qrText] változásakor; a képet a [builder] rajzolja.
  const QrReveal({required this.qrText, required this.builder, super.key});

  /// A söprés ideje.
  static const Duration duration = Duration(milliseconds: 240);

  /// A mostani kód szövege.
  final String qrText;

  /// Egy kód képe a szövegéből.
  final Widget Function(String qrText) builder;

  @override
  State<QrReveal> createState() => _QrRevealState();
}

class _QrRevealState extends State<QrReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: QrReveal.duration,
    value: 1,
  );
  String? _previousText;

  @override
  void didUpdateWidget(QrReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.qrText == widget.qrText) return;
    _previousText = oldWidget.qrText;
    unawaited(_controller.forward(from: 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final previous = _previousText;
      if (previous == null || _controller.isCompleted) {
        return widget.builder(widget.qrText);
      }
      final shown = Curves.easeOut.transform(_controller.value);
      return Stack(
        children: [
          Opacity(opacity: 0.3, child: widget.builder(previous)),
          ClipRect(
            clipper: _TopRevealClipper(shown),
            child: widget.builder(widget.qrText),
          ),
        ],
      );
    },
  );
}

/// A felső [fraction] részt hagyja látni.
class _TopRevealClipper extends CustomClipper<Rect> {
  _TopRevealClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width, size.height * fraction);

  @override
  bool shouldReclip(_TopRevealClipper oldClipper) =>
      oldClipper.fraction != fraction;
}
