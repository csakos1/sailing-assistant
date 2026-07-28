import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';

/// Egy cella az élő képernyő bal oldali fő oszlopában (ADR 0042 D1).
///
/// Három rekesze van: felül a verzál felirat (mellette jobbra a [trailing],
/// ide kerülnek a konfidencia-pöttyök, ADR 0042 D8), középen az érték, alul
/// pedig az opcionális [support] kísérő sor.
///
/// Az érték **cellánkénti** `FittedBox(scaleDown)` alatt van (ADR 0042 D4 +
/// Addendum 1). Ez szerkezeti kényszer, nem konvenció: a `FittedBox` így nem
/// tud több cellára kiterjedni, tehát egy hosszabb érték nem kicsinyíti le a
/// szomszédait. A `180°` négy karaktere 76 pt-on 209,8 dp, ami keskeny
/// készüléken elfogyhat.
///
/// A [support] szándékosan a `FittedBox`-on **kívül** van: ha a kísérő sor a
/// [child]-ba kerülne, egy megjelenő `±4°` vagy `jobbra` felirat csendben
/// lekicsinyítené magát a hero-számot is.
///
/// A magasságot a szülő flexe adja, ezért `Expanded` vagy `Flexible` alatt,
/// illetve kötött magasságú dobozban kell használni.
class MainColumnCell extends StatelessWidget {
  /// Egy fő oszlop-cella.
  const MainColumnCell({
    required this.label,
    required this.child,
    this.trailing,
    this.support,
    this.padding = const EdgeInsets.fromLTRB(20, 14, 14, 12),
    super.key,
  });

  /// A cella verzál felirata (például `TWA KÖV.`).
  final String label;

  /// Az érték-widget; a cella a méretezésén kívül nem nyúl hozzá.
  final Widget child;

  /// A felirat sorának jobb szélére kerülő kiegészítő (konfidencia-pöttyök).
  final Widget? trailing;

  /// Az érték alatti kísérő sor (`±4°`, `jobbra`), vagy null.
  final Widget? support;

  /// A cella belső margója; a makettből kimért alapérték a középső és az
  /// alsó cellára illik, a hero felül eggyel többet kap.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final trailing = this.trailing;
    final support = this.support;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sectionLabelStyle.copyWith(color: tones.low),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: child,
              ),
            ),
          ),
          if (support != null) support,
        ],
      ),
    );
  }
}
