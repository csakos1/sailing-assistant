import 'package:flutter/material.dart';

/// A dialógus alsó akciósora (ADR 0047 E6, makett 11a, ADR 0048
/// Addendum 4 K22).
///
/// 52 px magas, egyenlő szélességű cellák, fölöttük és közöttük
/// hairline. Egyetlen cellával teljes szélességű akció (13i, 13j).
class ForetackDialogActionBar extends StatelessWidget {
  /// Akciósor a [cells] cellákkal, balról jobbra.
  const ForetackDialogActionBar({required this.cells, super.key});

  /// A cellák; jellemzően `ForetackDialogActionCell`-ek.
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    final hairline = BorderSide(
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: hairline)),
      child: SizedBox(
        height: 52,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < cells.length; index++)
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: index > 0 ? Border(left: hairline) : null,
                  ),
                  child: cells[index],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
