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
class FormActionBar extends StatelessWidget {
  /// Egy akció-sáv.
  const FormActionBar({
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.onSecondary,
    required this.primaryLabel,
    required this.onPrimary,
    super.key,
  });

  /// A bal oldali, kontúros gomb felirata.
  final String secondaryLabel;

  /// A bal oldali gomb ikonja.
  final IconData secondaryIcon;

  /// A bal oldali gomb akciója.
  final VoidCallback onSecondary;

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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSecondary,
                  icon: Icon(secondaryIcon, size: 18),
                  label: Text(secondaryLabel),
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
