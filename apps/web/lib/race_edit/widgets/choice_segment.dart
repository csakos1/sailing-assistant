import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';

/// Egy szegmens-cella: az érték és a felirata.
typedef ChoiceSegmentOption<T> = ({T value, String label});

/// Keretes, egymás melletti választó-cellák, pl. `[SZÁM | DNF | DSQ]`
/// (ADR 0048 Addendum 1 G4, Addendum 4 K11).
///
/// Egyszerre egy cella választott. Minden cella külön gomb: Tab-bal
/// elérhető és Enterrel választható.
class ChoiceSegment<T> extends StatelessWidget {
  /// Szegmens az [options] cellákkal; a [selected] a választott érték.
  const ChoiceSegment({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// A cellák balról jobbra.
  final List<ChoiceSegmentOption<T>> options;

  /// A választott érték.
  final T selected;

  /// Választáskor hívódik, a cella értékével.
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
      child: SizedBox(
        height: WebLayout.editorFieldHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < options.length; index++)
              _SegmentCell<T>(
                option: options[index],
                isSelected: options[index].value == selected,
                hasDividerBefore: index > 0,
                onSelected: onSelected,
              ),
          ],
        ),
      ),
    );
  }
}

class _SegmentCell<T> extends StatelessWidget {
  const _SegmentCell({
    required this.option,
    required this.isSelected,
    required this.hasDividerBefore,
    required this.onSelected,
  });

  final ChoiceSegmentOption<T> option;
  final bool isSelected;
  final bool hasDividerBefore;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: isSelected,
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected ? scheme.outlineVariant : null,
          border: hasDividerBefore
              ? Border(left: BorderSide(color: scheme.outline))
              : null,
        ),
        child: InkWell(
          onTap: () => onSelected(option.value),
          hoverColor: scheme.surfaceContainerHigh,
          focusColor: scheme.surfaceContainerHigh,
          child: ConstrainedBox(
            // 54×54-es cella; a hosszabb felirat (+1 NAP) szélesebb.
            constraints: const BoxConstraints(
              minWidth: WebLayout.editorFieldHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: Text(
                  option.label,
                  style: statusLabelStyle.copyWith(
                    fontSize: 10.5,
                    color: isSelected
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
