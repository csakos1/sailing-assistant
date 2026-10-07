import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/auth/sign_in/countdown_format.dart';
import 'package:foretack_web/auth/sign_in/qr_code_image.dart';

/// A QR és a csatlakozási kérelem visszaszámlálója (17a, 17d-1): 2 px-es
/// halk sáv és a hátralévő idő mono számmal.
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja.
class CountdownBar extends StatelessWidget {
  /// Sáv a [secondsLeft] és a [totalSeconds] arányával.
  const CountdownBar({
    required this.secondsLeft,
    required this.totalSeconds,
    super.key,
  });

  /// A hátralévő másodpercek.
  final int secondsLeft;

  /// A teljes idő másodpercben (a sáv teli állása).
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final low = Theme.of(context).extension<TextTones>()!.low;
    final fraction = totalSeconds <= 0
        ? 0.0
        : (secondsLeft / totalSeconds).clamp(0, 1).toDouble();
    return SizedBox(
      width: QrCodeImage.extent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 2,
              color: scheme.outlineVariant,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction,
                heightFactor: 1,
                child: ColoredBox(color: low),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatCountdown(secondsLeft),
            style: railNumberStyle.copyWith(color: low),
          ),
        ],
      ),
    );
  }
}
