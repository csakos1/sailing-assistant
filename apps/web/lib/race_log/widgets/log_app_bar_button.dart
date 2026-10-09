import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';

/// A napló AppBarjának ghost gombja ikonnal és felirattal (19d, ADR 0048
/// Addendum 8 Q3): Statisztika, Export, Új verseny.
///
/// Tooltip nincs, mert a felirat kiírja, mit csinál.
class LogAppBarButton extends StatelessWidget {
  /// Gomb a [label] felirattal és az [icon] ikonnal.
  const LogAppBarButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  /// A felirat.
  final String label;

  /// Az ikon.
  final IconData icon;

  /// A kattintás.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: Icon(icon),
    label: Text(label),
    style: logAppBarGhostStyle(Theme.of(context).colorScheme),
  );
}

/// A ghost gombok közös stílusa (Q3): 36 px magas, szögletes, átlátszó;
/// hoverre, fókuszra és lenyomva `surfaceContainerHigh`. A név-menü gombja
/// is ezt használja, a [padding] ott a lenyíló nyíl miatt aszimmetrikus.
ButtonStyle logAppBarGhostStyle(
  ColorScheme scheme, {
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12),
}) => _logAppBarBaseStyle(padding).copyWith(
  foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
  iconColor: WidgetStatePropertyAll(scheme.onSurfaceVariant),
  backgroundColor: WidgetStateProperty.resolveWith(
    (states) => _isHighlighted(states)
        ? scheme.surfaceContainerHigh
        : Colors.transparent,
  ),
);

/// A Feltöltés gombjának stílusa (Q3): teal keret, teal ikon és felirat;
/// üres naplóban, ahol ez a fő akció, kitöltött teal ([isFilled]).
ButtonStyle logAppBarUploadStyle(
  ColorScheme scheme, {
  required bool isFilled,
}) {
  final base = _logAppBarBaseStyle(
    const EdgeInsets.symmetric(horizontal: 14),
  );
  if (isFilled) {
    return base.copyWith(
      foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
      iconColor: WidgetStatePropertyAll(scheme.onPrimary),
      backgroundColor: WidgetStatePropertyAll(scheme.primary),
      // A kitöltött gombon a Material saját hover-rétege jelez.
      overlayColor: WidgetStateProperty.resolveWith(
        (states) => _isHighlighted(states)
            ? scheme.onPrimary.withValues(alpha: 0.08)
            : Colors.transparent,
      ),
    );
  }
  return base.copyWith(
    foregroundColor: WidgetStatePropertyAll(scheme.primary),
    iconColor: WidgetStatePropertyAll(scheme.primary),
    side: WidgetStatePropertyAll(BorderSide(color: scheme.primary)),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => _isHighlighted(states)
          ? scheme.secondaryContainer
          : Colors.transparent,
    ),
  );
}

bool _isHighlighted(Set<WidgetState> states) =>
    states.contains(WidgetState.hovered) ||
    states.contains(WidgetState.focused) ||
    states.contains(WidgetState.pressed);

// A weben a gombok alapból kompakt sűrűséget kapnak (32 px); a magasság
// és a sűrűség ezért rögzített (ADR 0048 Addendum 5 L6).
ButtonStyle _logAppBarBaseStyle(EdgeInsetsGeometry padding) => ButtonStyle(
  minimumSize: const WidgetStatePropertyAll(
    Size(0, WebLayout.appBarControlHeight),
  ),
  fixedSize: const WidgetStatePropertyAll(
    Size.fromHeight(WebLayout.appBarControlHeight),
  ),
  padding: WidgetStatePropertyAll(padding),
  iconSize: const WidgetStatePropertyAll(18),
  overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  elevation: const WidgetStatePropertyAll(0),
  visualDensity: VisualDensity.standard,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
  textStyle: WidgetStatePropertyAll(
    supportTextStyle.copyWith(fontWeight: FontWeight.w600),
  ),
);
