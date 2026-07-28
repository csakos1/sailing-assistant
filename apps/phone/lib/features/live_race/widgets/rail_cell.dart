import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';

/// Egy cella az élő képernyő jobb oldali adatsínjében (ADR 0042 D1).
///
/// Felirat + érték, opcionálisan egy kísérő sorral ([support]) és annak
/// nyilával ([supportArrow]). A kísérő sor viszi a VMG cél-értékét és a
/// VMG-steer korrekciót (ADR 0042 D3); ha nincs cél, a sor **elmarad** —
/// nem gondolatjel áll benne, mert az érték önmagában is teljes.
///
/// Az érték **cellánkénti** `FittedBox(scaleDown)` alatt van (ADR 0042 D4):
/// a `1,85 km` és a `83 perc` hét karaktere 20 pt-on 105 dp-t kér, a sín
/// belső szélessége viszont 104 — a ritka hosszú alak ~1%-ot zsugorodik, a
/// gyakori rövidek érintetlenek.
///
/// A magasságot a `DataRail` flexe adja.
class RailCell extends StatelessWidget {
  /// Egy sín-cella.
  const RailCell({
    required this.label,
    required this.value,
    this.support,
    this.supportArrow,
    this.hasDivider = true,
    super.key,
  });

  /// A cella verzál felirata (például `BEARING`).
  final String label;

  /// A már formázott érték.
  final String value;

  /// Kísérő sor az érték alatt (például `cél 6,2`), vagy null.
  final String? support;

  /// A kísérő sor mellé kerülő nyíl (VMG-steer), vagy null.
  final Widget? supportArrow;

  /// Igaz, ha a cella alá hairline kerül; a sín utolsó cellája alatt nem.
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = theme.extension<TextTones>()!;
    final support = this.support;
    final supportArrow = this.supportArrow;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: hasDivider
            ? Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: railLabelStyle.copyWith(color: tones.low),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: numeralSmallStyle.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (support != null) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        support,
                        maxLines: 1,
                        style: numeralCaptionStyle.copyWith(color: tones.low),
                      ),
                    ),
                  ),
                  if (supportArrow != null) ...[
                    const SizedBox(width: 4),
                    supportArrow,
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
