import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// Egy választható év (vagy az „összes év") az évsávon: a kész felirat és
/// a választás kezelője.
typedef RaceLogYearOption = ({String label, VoidCallback onSelected});

/// A Versenynapló évsávja, a makett 7c változata (ADR 0047 Addendum 5 F2,
/// ADR 0048 Addendum 4 K4).
///
/// A kiválasztott év nagy számmal áll, mellette alulra igazítva a többi
/// év tompított, kattintható számként: maga a lista a választó,
/// külön ikon és lap nélkül. Egy elválasztó után jöhet az „összes év"
/// opció (14w). Alatta a versenyek száma verzál címkével.
///
/// Minden szöveget **készen kap**, a stat-csík mintájára: a lokalizáció és
/// az „összes év" tartomány-felirata (pl. `2021–2026`) a hívó dolga.
///
/// A tipográfia az ADR 0044 D39 elve szerint meglévő fokozat: a nagy szám
/// `numeralMediumStyle`, az opciók `numeralMicroStyle`, a címke
/// `numeralCaptionStyle`. A tompított opció `TextTones.low`, hoverre és
/// fókuszra `onSurfaceVariant` (ADR 0047 Addendum 4 E5).
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja, tehát a fában
/// mindig jelen van.
class RaceLogYearSelector extends StatelessWidget {
  /// Évsáv a [selectedLabel] kiválasztott évvel és az [options] többi
  /// évvel; az [allYearsOption] egy elválasztó után áll.
  const RaceLogYearSelector({
    required this.selectedLabel,
    required this.options,
    required this.countLabel,
    this.allYearsOption,
    super.key,
  });

  /// A kiválasztott év (vagy az összes év tartománya) felirata.
  final String selectedLabel;

  /// A többi választható év, a megjelenés sorrendjében.
  final List<RaceLogYearOption> options;

  /// Az „összes év" opció; `null`, ha éppen az van kiválasztva.
  final RaceLogYearOption? allYearsOption;

  /// A kiválasztott időszak verseny-számának kész felirata.
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final allYears = allYearsOption;

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
                Padding(
                  // A nagy szám és az opciók közti 18 px-es rés (7c).
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    selectedLabel,
                    style: numeralMediumStyle.copyWith(color: scheme.onSurface),
                  ),
                ),
                for (final option in options) _YearOptionButton(option: option),
                if (allYears != null) ...[
                  SizedBox(
                    width: 1,
                    height: 14,
                    child: ColoredBox(color: scheme.outline),
                  ),
                  _YearOptionButton(option: allYears),
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

/// Egy kattintható év: tompított, hoverre és fókuszra kivilágosodik.
class _YearOptionButton extends StatefulWidget {
  const _YearOptionButton({required this.option});

  final RaceLogYearOption option;

  @override
  State<_YearOptionButton> createState() => _YearOptionButtonState();
}

class _YearOptionButtonState extends State<_YearOptionButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final isHighlighted = _isHovered || _isFocused;

    return InkWell(
      onTap: widget.option.onSelected,
      onHover: (isHovered) => setState(() => _isHovered = isHovered),
      onFocusChange: (isFocused) => setState(() => _isFocused = isFocused),
      // A kiemelést a szín adja, nem a Material-réteg (E5: azonnali váltás).
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      child: Padding(
        // A 7c 2 px-es függőleges betéte; a 38-as szám aljához igazít.
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          widget.option.label,
          style: numeralMicroStyle.copyWith(
            color: isHighlighted ? scheme.onSurfaceVariant : tones.low,
          ),
        ),
      ),
    );
  }
}
