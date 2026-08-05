import 'package:flutter/material.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/features/race_detail/track_stats_formatters.dart';

/// Egy cella a napló stat-csíkján: verzál felirat és a mért érték.
typedef RaceLogStatCell = ({String label, MeasuredValue measured});

/// A kiválasztott év összesítő csíkja (ADR 0044 D42, D39).
///
/// Hairline-osztott, kártya-héj nélkül, a post-race stat-sor nyelvén: a
/// cellák között 1 px függőleges vonal, a csík fölött és alatt vízszintes.
///
/// A [cells] felirata és értéke **készen érkezik**: a lokalizált szöveg és
/// a formázás a képernyő dolga, így ez a widget nyelv-független marad, és
/// a betöltés alatti helyőrző is a hívó döntése.
///
/// A csík minden értéke a kiválasztott évre vonatkozik — a képernyőn nincs
/// év-független szám (D38).
///
/// A felirat `sectionLabelStyle`-t kap (D39). Ez tudatosan **eltér** a
/// detail-képernyő stat-cellájától, amely `railLabelStyle`-t használ: a
/// D39 tipográfia-táblája ezt a fokozatot rendeli a napló csíkjához.
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja, tehát a fában
/// mindig jelen van.
class RaceLogStatsStrip extends StatelessWidget {
  /// Egy összesítő csík tetszőleges számú cellával; a cellák egyenlően
  /// osztoznak a szélességen.
  const RaceLogStatsStrip({required this.cells, super.key})
    : assert(cells.length > 0, 'A stat-csík nem lehet cella nélkül.');

  /// A megjelenített cellák, balról jobbra.
  final List<RaceLogStatCell> cells;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final horizontal = SizedBox(
      height: 1,
      child: ColoredBox(color: scheme.outlineVariant),
    );
    final vertical = SizedBox(
      width: 1,
      child: ColoredBox(color: scheme.outlineVariant),
    );

    final row = <Widget>[];
    for (final (index, cell) in cells.indexed) {
      if (index > 0) row.add(vertical);
      row.add(Expanded(child: _StatCell(cell: cell)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        horizontal,
        // A függőleges választók teljes magassága stretch-et kíván, ahhoz
        // viszont a sor magasságát előre ismerni kell.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: row,
          ),
        ),
        horizontal,
      ],
    );
  }
}

/// Egy cella: verzál felirat, alatta az érték a mértékegységgel.
class _StatCell extends StatelessWidget {
  const _StatCell({required this.cell});

  final RaceLogStatCell cell;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            cell.label,
            textAlign: TextAlign.center,
            style: sectionLabelStyle.copyWith(color: tones.low),
          ),
          const SizedBox(height: 6),
          // Alapvonalra igazítva: az érték és a mértékegység két külön
          // fokozat, közös alapvonal nélkül a kettő elcsúszna.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                cell.measured.value,
                style: numeralSmallStyle.copyWith(color: scheme.onSurface),
              ),
              // Hiányzó mérésnél nincs mértékegység, tehát a rés sem kell.
              if (cell.measured.unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  cell.measured.unit,
                  style: supportTextStyle.copyWith(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
