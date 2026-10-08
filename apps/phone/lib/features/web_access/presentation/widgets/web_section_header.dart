import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// Egy csoport fejléce a kezelőképernyőkön: verzál címke, hairline és a
/// darabszám (makett 18i, 18k).
class WebSectionHeader extends StatelessWidget {
  /// Fejléc a [label] (már verzál) címkével és a [count] darabszámmal.
  const WebSectionHeader({required this.label, this.count, super.key});

  /// A verzál felirat; a nagybetűsítés a hívóé (név vagy ARB).
  final String label;

  /// A csoport elemeinek száma; `null`-nál nincs szám.
  final int? count;

  /// A címke legfeljebb ekkora része a sornak; a maradék a vonalé.
  static const double maximumLabelShare = 0.7;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final number = count;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: LayoutBuilder(
        // A címke nem `Flexible`: egy `Flexible` és egy `Expanded` a szabad
        // helyet felezi, és a vonal a sor közepén véget érne. Egy hosszú
        // név a korlátnál levágódik.
        builder: (context, constraints) => Row(
          spacing: 10,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * maximumLabelShare,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sectionLabelStyle.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant,
              ),
            ),
            if (number != null)
              Text(
                '$number',
                style: railNumberStyle.copyWith(color: tones.low),
              )
            else
              // Szám nélkül a vonal 10 px-szel a margó előtt ér véget
              // (makett 18l).
              const SizedBox(width: 0),
          ],
        ),
      ),
    );
  }
}
