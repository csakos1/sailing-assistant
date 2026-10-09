import 'package:flutter/material.dart';
import 'package:foretack_web/app/web_layout.dart';

/// A napló AppBarjának ikon-gombja (Statisztika, Export).
///
/// Szöveggel egy 800 px-es ablakban már nem férnének el a többi vezérlő
/// mellett (ADR 0049 Addendum 1 P1, ADR 0050 Addendum 3 G1); a többi
/// vezérlővel egy magas (ADR 0048 Addendum 5 L6).
class LogAppBarIconButton extends StatelessWidget {
  /// Gomb az [icon] ikonnal, a [tooltip] felirattal.
  const LogAppBarIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  /// A tooltip és az akadálymentes címke.
  final String tooltip;

  /// Az ikon.
  final IconData icon;

  /// A kattintás.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    icon: Icon(icon),
    color: Theme.of(context).colorScheme.onSurface,
    style: IconButton.styleFrom(
      fixedSize: const Size.square(WebLayout.appBarControlHeight),
      minimumSize: Size.zero,
      padding: const EdgeInsets.all(6),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    onPressed: onPressed,
  );
}
