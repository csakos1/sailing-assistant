import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// A webes hozzáférés gombjainak fajtája.
enum WebActionKind {
  /// Teal kitöltésű, elsődleges gomb.
  primary,

  /// Átlátszó, `outline` keretes, másodlagos gomb.
  secondary,

  /// Átlátszó, `error` keretes, romboló gomb (Kiléptetés, Visszavonás,
  /// ADR 0051 Addendum 10 Z9).
  destructive,
}

/// A webes hozzáférés képernyőinek gombja (makett 18d-2…5, 18e, 18e-2,
/// 18f, 18g, 18h, 18i).
///
/// 48 px magas, lekerekítés nélkül, 14/600 felirattal, ahogy az app többi
/// akció-gombja (`ListActionBar`, `FormActionBar`) is szögletes. A
/// sorokban álló, kompakt változat ([isCompact]) 40 px magas, 13/600
/// (makett 18h, 18i). A tiltott gomb 35 %-ra halványul, mint a dialógus
/// akció-cellája (makett 13g); a dolgozó gomb forgót mutat, nem
/// kattintható, de nem halványul (13h).
class WebActionButton extends StatelessWidget {
  /// Teal kitöltésű, elsődleges gomb.
  const WebActionButton.primary({
    required this.label,
    required this.onPressed,
    this.isBusy = false,
    this.isCompact = false,
    super.key,
  }) : kind = WebActionKind.primary;

  /// Keretes, másodlagos gomb.
  const WebActionButton.secondary({
    required this.label,
    required this.onPressed,
    this.isBusy = false,
    this.isCompact = false,
    super.key,
  }) : kind = WebActionKind.secondary;

  /// Piros keretes, romboló gomb (Z9).
  const WebActionButton.destructive({
    required this.label,
    required this.onPressed,
    this.isBusy = false,
    this.isCompact = false,
    super.key,
  }) : kind = WebActionKind.destructive;

  /// A gomb magassága a makett szerint.
  static const double height = 48;

  /// A kompakt (sorban álló) gomb magassága (makett 18h, 18i).
  static const double compactHeight = 40;

  /// A tiltott gomb átlátszósága (makett 13g).
  static const double disabledOpacity = 0.35;

  /// A felirat.
  final String label;

  /// A kattintás; `null`-nál a gomb tiltott.
  final VoidCallback? onPressed;

  /// Fut-e a gomb művelete (forgó a felirat helyén).
  final bool isBusy;

  /// A sorokban álló, kisebb változat.
  final bool isCompact;

  /// A gomb fajtája.
  final WebActionKind kind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPrimary = kind == WebActionKind.primary;
    final foreground = isPrimary ? scheme.onPrimary : scheme.onSurface;
    final child = isBusy
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    final onTap = isBusy ? null : onPressed;
    final minimumSize = Size(0, isCompact ? compactHeight : height);
    // A makett kompakt romboló gombja 14, a többi 18 px-es betéttel áll.
    final padding = EdgeInsets.symmetric(
      horizontal: isCompact && kind == WebActionKind.destructive ? 14 : 18,
    );
    final labelStyle = supportTextStyle.copyWith(
      fontSize: isCompact ? 13 : 14,
      fontWeight: FontWeight.w600,
    );
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
              minimumSize: minimumSize,
              padding: padding,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: labelStyle,
            ),
            child: child,
          )
        : OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: foreground,
              disabledForegroundColor: foreground,
              side: BorderSide(
                color: kind == WebActionKind.destructive
                    ? scheme.error
                    : scheme.outline,
              ),
              shape: const RoundedRectangleBorder(),
              minimumSize: minimumSize,
              padding: padding,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: labelStyle,
            ),
            child: child,
          );
    return Opacity(
      opacity: onPressed == null && !isBusy ? disabledOpacity : 1,
      child: button,
    );
  }
}
