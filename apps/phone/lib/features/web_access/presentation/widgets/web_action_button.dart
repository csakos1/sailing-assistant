import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// A webes hozzáférés képernyőinek gombja (makett 18d-2…5, 18e, 18e-2,
/// 18f, 18g).
///
/// 48 px magas, lekerekítés nélkül, 14/600 felirattal, ahogy az app többi
/// akció-gombja (`ListActionBar`, `FormActionBar`) is szögletes. A
/// [WebActionButton.primary] teal alapú, a [WebActionButton.secondary]
/// átlátszó, egy `outline` színű kerettel. A tiltott gomb 35 %-ra
/// halványul, mint a dialógus akció-cellája (makett 13g); a dolgozó gomb
/// forgót mutat, nem kattintható, de nem halványul (13h).
class WebActionButton extends StatelessWidget {
  /// Teal kitöltésű, elsődleges gomb.
  const WebActionButton.primary({
    required this.label,
    required this.onPressed,
    this.isBusy = false,
    super.key,
  }) : isPrimary = true;

  /// Keretes, másodlagos gomb.
  const WebActionButton.secondary({
    required this.label,
    required this.onPressed,
    this.isBusy = false,
    super.key,
  }) : isPrimary = false;

  /// A gomb magassága a makett szerint.
  static const double height = 48;

  /// A tiltott gomb átlátszósága (makett 13g).
  static const double disabledOpacity = 0.35;

  /// A felirat.
  final String label;

  /// A kattintás; `null`-nál a gomb tiltott.
  final VoidCallback? onPressed;

  /// Fut-e a gomb művelete (forgó a felirat helyén).
  final bool isBusy;

  /// Elsődleges (teal) vagy másodlagos (keretes) gomb.
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = isPrimary ? scheme.onPrimary : scheme.onSurface;
    final child = isBusy
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    final onTap = isBusy ? null : onPressed;
    // A tiltott színek a rendesek: a halványítást az `Opacity` adja, így a
    // dolgozó (szintén kattinthatatlan) gomb nem halványul.
    final button = isPrimary
        ? FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: foreground,
              disabledBackgroundColor: scheme.primary,
              disabledForegroundColor: foreground,
              shape: const RoundedRectangleBorder(),
              minimumSize: const Size(0, height),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: _labelStyle,
            ),
            child: child,
          )
        : OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: foreground,
              disabledForegroundColor: foreground,
              side: BorderSide(color: scheme.outline),
              shape: const RoundedRectangleBorder(),
              minimumSize: const Size(0, height),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: _labelStyle,
            ),
            child: child,
          );
    return Opacity(
      opacity: onPressed == null && !isBusy ? disabledOpacity : 1,
      child: button,
    );
  }
}

final TextStyle _labelStyle = supportTextStyle.copyWith(
  fontSize: 14,
  fontWeight: FontWeight.w600,
);
