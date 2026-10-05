import 'package:flutter/material.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/race_log/table/cells/table_cell_styles.dart';

/// Egy sáv a szélsávok listájában: a címke és a versenyek száma.
typedef WindBandBar = ({String label, int count});

/// A versenyek eloszlása az átlagos szél szerint, vízszintes sávokkal (ADR
/// 0049 Addendum 1 P3).
///
/// A sáv hossza a legnagyobb darabszámhoz arányos, színe a `primary`.
/// Chart-függőség nélkül, a meglévő tokenekből.
class WindBandBars extends StatelessWidget {
  /// Sávok a `bars` soraival, fentről lefelé.
  const WindBandBars({required this.bars, super.key});

  /// A sorok, a sávok sorrendjében.
  final List<WindBandBar> bars;

  @override
  Widget build(BuildContext context) {
    var largest = 0;
    for (final bar in bars) {
      if (bar.count > largest) largest = bar.count;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WebLayout.columnInset),
      child: Column(
        children: [
          for (final bar in bars)
            _BarRow(
              bar: bar,
              // Üres eloszlásnál nincs mihez arányítani: minden sáv nulla.
              fraction: largest == 0 ? 0 : bar.count / largest,
            ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.bar, required this.fraction});

  final WindBandBar bar;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              bar.label,
              style: tableNumberStyle.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: SizedBox(
                height: 10,
                child: ColoredBox(color: scheme.primary),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${bar.count}',
              textAlign: TextAlign.end,
              style: tableNumberStyle.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
