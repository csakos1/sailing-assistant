import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// A 90% és a 100% fölötti idő aránya egymásra rajzolva (ADR 0049
/// Addendum 5, 16a „Mini sáv").
///
/// A sáv 0–100%-os skála a mért időre. A sötétebb rész a 90% fölötti, a
/// világosabb a 100% fölötti idő; a 100% fölötti a 90% fölötti része,
/// ezért a bal szélről indul, ugyanabban a sávban.
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja.
class PolarShareBar extends StatelessWidget {
  /// Sáv a két aránnyal (0–1).
  const PolarShareBar({
    required this.shareAtLeast90,
    required this.shareAtLeast100,
    super.key,
  });

  /// A legalább 90%-os idő aránya.
  final double shareAtLeast90;

  /// A legalább 100%-os idő aránya.
  final double shareAtLeast100;

  /// A sáv magassága.
  static const double height = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      height: height,
      child: ColoredBox(
        color: scheme.surfaceContainerHigh,
        child: Stack(
          children: [
            // A makett a régi évsáv halk színét kérte (#4E6070); a mai
            // évsáv halk színe a `text-low` token, így az marad tokenben.
            _part(shareAtLeast90, theme.extension<TextTones>()!.low),
            _part(shareAtLeast100, scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _part(double share, Color color) => FractionallySizedBox(
    alignment: Alignment.centerLeft,
    widthFactor: share.clamp(0, 1).toDouble(),
    heightFactor: 1,
    child: ColoredBox(color: color),
  );
}
