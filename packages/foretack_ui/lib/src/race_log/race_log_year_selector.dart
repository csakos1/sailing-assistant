import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// Egy választható év (vagy az „összes év") az évsávon: a kész felirat és
/// a választás kezelője.
typedef RaceLogYearOption = ({String label, VoidCallback onSelected});

/// Egy év az évsávon: a kész felirat, kiválasztott-e, és a választás
/// kezelője (ADR 0048 Addendum 7 N1).
typedef RaceLogYearEntry = ({
  String label,
  bool isSelected,
  VoidCallback onSelected,
});

/// A Versenynapló évsávja, a makett 7c változata (ADR 0047 Addendum 5 F2,
/// ADR 0048 Addendum 4 K4, Addendum 7 N1).
///
/// Az évek fix sorrendben, a helyükön állnak: a kiválasztott év a helyén
/// nagy számmal, a többi tompított, kattintható számként, alulra igazítva.
/// A váltás rövid animáció, így a jobbra lévő évek csúszása nem ugrás. Egy
/// elválasztó után jöhet az „összes év" opció (14w). Alatta, a bal szélen
/// a versenyek száma verzál címkével.
///
/// Ha egyik év sincs kiválasztva („összes év"), a [leadingLabel] (pl. a
/// `2021–2026` tartomány) áll nagyban a sor elején.
///
/// Minden szöveget **készen kap**, a stat-csík mintájára: a lokalizáció és
/// a tartomány-felirat a hívó dolga.
///
/// A tipográfia az ADR 0044 D39 elve szerint meglévő fokozat: a nagy szám
/// `numeralMediumStyle`, az opciók `numeralMicroStyle`, a címke
/// `numeralCaptionStyle`. A tompított opció `TextTones.low`, hoverre és
/// fókuszra `onSurfaceVariant` (ADR 0047 Addendum 4 E5).
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja, tehát a fában
/// mindig jelen van.
class RaceLogYearSelector extends StatelessWidget {
  /// Évsáv a [years] évekkel a megjelenés sorrendjében; az [allYearsOption]
  /// egy elválasztó után áll.
  const RaceLogYearSelector({
    required this.years,
    required this.countLabel,
    this.leadingLabel,
    this.allYearsOption,
    super.key,
  });

  /// Az évek a megjelenés (csökkenő) sorrendjében; legfeljebb egy
  /// kiválasztott.
  final List<RaceLogYearEntry> years;

  /// A sor elején nagyban álló felirat, ha egyik év sincs kiválasztva.
  final String? leadingLabel;

  /// Az „összes év" opció; `null`, ha éppen az van kiválasztva.
  final RaceLogYearOption? allYearsOption;

  /// A kiválasztott időszak verseny-számának kész felirata.
  final String countLabel;

  /// A méret- és színváltás hossza (N1).
  static const Duration transitionDuration = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final allYears = allYearsOption;
    final leading = leadingLabel;

    return ColoredBox(
      color: scheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                if (leading != null)
                  Padding(
                    // A nagy szám és az opciók közti 18 px-es rés (7c).
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      leading,
                      style: numeralMediumStyle.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                for (final year in years) _YearButton(entry: year),
                if (allYears != null) ...[
                  SizedBox(
                    width: 1,
                    height: 14,
                    child: ColoredBox(color: scheme.outline),
                  ),
                  _YearButton(
                    entry: (
                      label: allYears.label,
                      isSelected: false,
                      onSelected: allYears.onSelected,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              countLabel,
              style: numeralCaptionStyle.copyWith(color: tones.low),
            ),
          ],
        ),
      ),
    );
  }
}

/// Egy év a sávon: kiválasztva nagy és világos, különben tompított és
/// kattintható, hoverre és fókuszra kivilágosodik.
class _YearButton extends StatefulWidget {
  const _YearButton({required this.entry});

  final RaceLogYearEntry entry;

  @override
  State<_YearButton> createState() => _YearButtonState();
}

class _YearButtonState extends State<_YearButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final isSelected = widget.entry.isSelected;
    final isHighlighted = _isHovered || _isFocused;
    final style = isSelected
        ? numeralMediumStyle.copyWith(color: scheme.onSurface)
        : numeralMicroStyle.copyWith(
            color: isHighlighted ? scheme.onSurfaceVariant : tones.low,
          );

    return InkWell(
      // A kiválasztott évet nincs mit választani (N1).
      onTap: isSelected ? null : widget.entry.onSelected,
      onHover: (isHovered) => setState(() => _isHovered = isHovered),
      onFocusChange: (isFocused) => setState(() => _isFocused = isFocused),
      // A kiemelést a szín adja, nem a Material-réteg (E5: azonnali váltás).
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      child: AnimatedPadding(
        duration: RaceLogYearSelector.transitionDuration,
        curve: Curves.easeOut,
        // Kicsiben a 7c 2 px-es függőleges betéte (a 38-as szám aljához
        // igazít); nagyban a két oldali 4 px adja a 18 px-es rést.
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 4)
            : const EdgeInsets.symmetric(vertical: 2),
        child: AnimatedDefaultTextStyle(
          duration: RaceLogYearSelector.transitionDuration,
          curve: Curves.easeOut,
          style: style,
          child: Text(widget.entry.label),
        ),
      ),
    );
  }
}
