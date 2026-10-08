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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final number = count;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        spacing: 10,
        children: [
          // Egy hosszú név ne tolja ki a vonalat és a számot.
          Flexible(
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
            ),
        ],
      ),
    );
  }
}
