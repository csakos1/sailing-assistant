import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';

/// Rögzített, kétgombos akció-sáv egy űrlap alján (ADR 0044 D1).
///
/// A gombok **nem a görgetett törzsben** ülnek: hat bójánál a mentés csak
/// görgetés után lenne elérhető, ami a kikötőben, indulás előtt rossz csere.
/// A sáv a `Scaffold` alapértelmezett `resizeToAvoidBottomInset`-je miatt
/// magától a billentyűzet fölé emelkedik, ezért a [SafeArea] csak alul kell.
///
/// A geometria (52 dp, r14, 10 dp rés, két egyenlő `Expanded`) **itt van
/// bezárva**, nem a hívóban — így a következő űrlap nem tudja véletlenül
/// elrontani, ugyanazon a megfontoláson, mint az ADR 0042 cellánkénti
/// `FittedBox`-a.
///
/// A másodlagos gomb **elhagyható** (ADR 0046 D4): bója nélküli
/// versenynél nincs mit hozzáadni, ilyenkor a sáv egyetlen, teljes
/// szélességű primary gombra esik. A három `secondary*` mező
/// **együtt jár**: vagy mind a három megvan, vagy egyik sem — ezt a
/// konstruktor assertje őrzi.
class FormActionBar extends StatelessWidget {
  /// Egy akció-sáv. A `secondary*` hármas együtt hagyható el.
  const FormActionBar({
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.secondaryIcon,
    this.onSecondary,
    super.key,
  }) : assert(
         (secondaryLabel == null) == (secondaryIcon == null) &&
             (secondaryLabel == null) == (onSecondary == null),
         'A secondary hármas együtt jár: mind a három, vagy egyik sem.',
       );

  /// A bal oldali, kontúros gomb felirata; `null` = nincs ilyen gomb.
  final String? secondaryLabel;

  /// A bal oldali gomb ikonja; `null` = nincs ilyen gomb.
  final IconData? secondaryIcon;

  /// A bal oldali gomb akciója; `null` = nincs ilyen gomb.
  final VoidCallback? onSecondary;

  /// A jobb oldali, kitöltött gomb felirata.
  final String primaryLabel;

  /// A jobb oldali gomb akciója.
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    );

    // Lokálisba másolva, mert a publikus mezők nem promotálódnak
    // null-vizsgálatra (a field promotion csak privát final mezőkre áll).
    final label = secondaryLabel;
    final icon = secondaryIcon;
    final onTap = onSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              // A hármast az assert együtt tartja, de a promocióhoz a
              // fordítónak mindhárom lokális null-vizsgálata kell — így
              // nem marad force-unwrap a widget-fában.
              if (label != null && icon != null && onTap != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    icon: Icon(icon, size: 18),
                    label: Text(label),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: shape,
                      side: BorderSide(color: scheme.outline, width: 1.5),
                      foregroundColor: scheme.onSurface,
                      textStyle: supportTextStyle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: onPrimary,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: shape,
                    textStyle: supportTextStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(primaryLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
