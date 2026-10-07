import 'package:flutter/material.dart';
import 'package:foretack_web/auth/sign_in/qr_code_image.dart';

/// A QR helyén álló állapotdoboz (17c, 17d-1): 264 px-es négyzet,
/// `surfaceContainer` háttér, `outline` keret, középre zárt tartalom.
class SignInStatusBox extends StatelessWidget {
  /// Doboz a [children] tartalommal; a [footer] az alsó élhez tapad.
  const SignInStatusBox({required this.children, this.footer, super.key});

  /// A középre zárt tartalom, 14 px-es közökkel.
  final List<Widget> children;

  /// Az alsó élen álló elem (17c: a 2 px-es teal sáv).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final footer = this.footer;
    return Container(
      width: QrCodeImage.extent,
      height: QrCodeImage.extent,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border.all(color: scheme.outline),
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 14,
                children: children,
              ),
            ),
          ),
          if (footer != null)
            Positioned(left: 0, right: 0, bottom: 0, child: footer),
        ],
      ),
    );
  }
}
