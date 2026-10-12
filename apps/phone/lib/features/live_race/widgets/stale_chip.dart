import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// Az „elavult adat" chip a Műszerek csíkján (ADR 0042 D12, ADR 0056 U3,
/// U4).
///
/// Kontúros pill, nem tömör doboz: az elavulás **nem** riasztás — az értékek
/// megmaradnak a képernyőn, csak a koruk kérdéses —, ezért a jelzés a
/// warning-tokent viszi, de nem foglal el hátteret a csíkban.
class StaleChip extends StatelessWidget {
  /// Chip a [label] felirattal és a [color] (warning) színnel.
  const StaleChip({required this.label, required this.color, super.key});

  /// A chip felirata (`ELAVULT`).
  final String label;

  /// A keret, az ikon és a felirat színe.
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: sectionLabelStyle.copyWith(color: color)),
      ],
    ),
  );
}
