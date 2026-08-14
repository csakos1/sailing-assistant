import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/features/race_setup/widgets/form_bar_action.dart';

/// A másodlagos sor magassága (ADR 0044 D50, geometria: ARCHITECTURE 8.11).
const double _secondaryHeight = 56;

/// A primary sáv magassága.
const double _primaryHeight = 60;

/// A cellák közti osztó vonal vastagsága.
const double _dividerWidth = 1;

/// Az ikon mérete a másodlagos cellákban.
const double _actionIconSize = 18;

/// A felirat fokozata mindkét sorban; a súly soronként tér el.
const double _labelSize = 15;

/// Rögzített, kétsoros akció-sáv egy űrlap alján (ADR 0044 D1, D50).
///
/// A gombok **nem a görgetett törzsben** ülnek: hat bójánál a mentés csak
/// görgetés után lenne elérhető, ami a kikötőben, indulás előtt rossz csere.
/// A sáv a `Scaffold` alapértelmezett `resizeToAvoidBottomInset`-je miatt
/// magától a billentyűzet fölé emelkedik, ezért a [SafeArea] csak alul kell.
///
/// Fölül a [secondaryActions] osztozik egyenlően a soron, alatta a teljes
/// szélességű primary gomb. A geometria (56 / 60 dp, r0, osztó hairline)
/// **itt van bezárva**, nem a hívóban — így a következő űrlap nem tudja
/// véletlenül elrontani, ugyanazon a megfontoláson, mint az ADR 0042
/// cellánkénti `FittedBox`-a.
///
/// Az **üres** [secondaryActions] azt jelenti, hogy nincs felső sor: bója
/// nélküli versenynél nincs mit hozzáadni, és a sáv egyetlen, teljes
/// szélességű primary gombra esik (ADR 0046 D4).
class FormActionBar extends StatelessWidget {
  /// Egy akció-sáv. A [secondaryActions] üresen hagyható.
  const FormActionBar({
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryActions = const [],
    super.key,
  });

  /// A felső sor akciói balról jobbra; üres lista = nincs felső sor.
  final List<FormBarAction> secondaryActions;

  /// Az alsó, teljes szélességű gomb felirata.
  final String primaryLabel;

  /// Az alsó gomb akciója.
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (secondaryActions.isNotEmpty)
              _SecondaryRow(actions: secondaryActions),
            SizedBox(
              height: _primaryHeight,
              child: FilledButton(
                onPressed: onPrimary,
                style: FilledButton.styleFrom(
                  shape: const RoundedRectangleBorder(),
                  textStyle: supportTextStyle.copyWith(
                    fontSize: _labelSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(primaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A sáv felső sora: a cellák egyenlően osztoznak, köztük hairline.
class _SecondaryRow extends StatelessWidget {
  const _SecondaryRow({required this.actions});

  final List<FormBarAction> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surfaceContainer,
      child: SizedBox(
        height: _secondaryHeight,
        // A kötött magasság miatt a stretch itt biztonságos: az osztó
        // vonal ebből kapja a teljes magasságát.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < actions.length; index++) ...[
              // Osztó csak a cellák KÖZÖTT: a sor szélét fölül a törzs
              // hairline-ja, alul a primary gomb zárja.
              if (index > 0)
                SizedBox(
                  width: _dividerWidth,
                  child: ColoredBox(color: scheme.outlineVariant),
                ),
              Expanded(child: _ActionCell(action: actions[index])),
            ],
          ],
        ),
      ),
    );
  }
}

/// Egy cella a felső sorban: ikon + felirat, keret és lekerekítés nélkül.
class _ActionCell extends StatelessWidget {
  const _ActionCell({required this.action});

  final FormBarAction action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextButton.icon(
      onPressed: action.onTap,
      icon: Icon(action.icon, size: _actionIconSize),
      label: Text(action.label),
      style: TextButton.styleFrom(
        shape: const RoundedRectangleBorder(),
        foregroundColor: scheme.onSurface,
        textStyle: supportTextStyle.copyWith(
          fontSize: _labelSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
