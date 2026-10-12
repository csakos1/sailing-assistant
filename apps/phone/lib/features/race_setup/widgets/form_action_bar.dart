import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_setup/widgets/form_bar_action.dart';

/// A másodlagos sor magassága (ADR 0044 D50, az U7 óta a 33a szerint).
const double _secondaryHeight = 58;

/// A primary sáv magassága (33a).
const double _primaryHeight = 62;

/// A cellák közti osztó vonal vastagsága.
const double _dividerWidth = 1;

/// Az ikon mérete a másodlagos cellákban.
const double _actionIconSize = 18;

/// A feliratok fokozata (33a): a felső sor 14 / w600, a primary 15 / w700.
const double _secondaryLabelSize = 14;
const double _primaryLabelSize = 15;

/// Rögzített, kétsoros akció-sáv egy űrlap alján (ADR 0044 D1, D50).
///
/// A gombok **nem a görgetett törzsben** ülnek: hat bójánál a mentés csak
/// görgetés után lenne elérhető, ami a kikötőben, indulás előtt rossz csere.
/// A sáv a `Scaffold` alapértelmezett `resizeToAvoidBottomInset`-je miatt
/// magától a billentyűzet fölé emelkedik, ezért a [SafeArea] csak alul kell.
///
/// Fölül a [secondaryActions] osztozik egyenlően a soron, alatta a teljes
/// szélességű primary gomb. A geometria (58 / 62 dp, r0, osztó hairline)
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
                    fontSize: _primaryLabelSize,
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
      // Egy fokkal a törzs fölött: a `surfaceContainer` bitre azonos a
      // bója-sorok mezőinek kitöltésével, és eszközön egybeolvadt vele.
      color: scheme.surfaceContainerHigh,
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
          fontSize: _secondaryLabelSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
