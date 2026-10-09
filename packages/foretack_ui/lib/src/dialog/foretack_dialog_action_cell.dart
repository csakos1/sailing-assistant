import 'package:flutter/material.dart';
import 'package:foretack_ui/src/theme/foretack_typography.dart';

/// Egy akció-cella a dialógus akciósorában (ADR 0047 E6, makett 11a,
/// 13g–13h, ADR 0048 Addendum 4 K22).
///
/// Állapotai:
/// - aktív: kattintható, hover- és fókusz-háttérrel;
/// - tiltott (`onPressed == null`): 35 %-ra halványul (13g);
/// - dolgozik (`isBusy`): forgó a felirat előtt, nem kattintható, de nem
///   halványul, mert a művelet fut, nem hiányzik a feltétele (13h).
///
/// A destruktív cella felirata piros (`colorScheme.error`).
class ForetackDialogActionCell extends StatelessWidget {
  /// Cella a [label] felirattal; az [onPressed] `null`-nál tiltott.
  const ForetackDialogActionCell({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.isBusy = false,
    this.autofocus = false,
    this.focusNode,
    super.key,
  });

  /// A cella felirata.
  final String label;

  /// A kattintás; `null`-nál a cella tiltott.
  final VoidCallback? onPressed;

  /// Visszafordíthatatlan műveletet indít-e (piros felirat).
  final bool isDestructive;

  /// Fut-e a cella művelete (forgó, kattintás nélkül).
  final bool isBusy;

  /// Megnyitáskor fókuszt kap-e (a biztonságos akció, K13).
  final bool autofocus;

  /// A cella fókusza, ha a hívó később maga mozgatja ide (például a fájl
  /// kiválasztása után a Feltöltés cellára, 13f).
  final FocusNode? focusNode;

  /// A tiltott cella átlátszósága a makett 13g-je szerint.
  static const double disabledOpacity = 0.35;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null && !isBusy;
    final text = Text(
      label,
      style: supportTextStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDestructive ? scheme.error : scheme.onSurface,
      ),
    );

    return Opacity(
      opacity: onPressed == null && !isBusy ? disabledOpacity : 1,
      child: InkWell(
        autofocus: autofocus,
        focusNode: focusNode,
        onTap: isEnabled ? onPressed : null,
        hoverColor: scheme.surfaceContainerHigh,
        focusColor: scheme.surfaceContainerHigh,
        child: Center(
          child: isBusy
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                    const SizedBox(width: 10),
                    text,
                  ],
                )
              : text,
        ),
      ),
    );
  }
}
