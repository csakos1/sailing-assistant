import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/marine_colors.dart';
import 'package:phone/features/live_race/live_formatters.dart';
import 'package:phone/features/live_race/widgets/metric_value_text.dart';

/// A TWA-érték: magnitúdó + oldal-nyíl (§8.7). A nyíl azon az oldalon,
/// ahonnan a szél jön (az `Angle` előjele), BEFELÉ (a szám felé) mutat;
/// starboard → zöld, port → piros. Tömör háromszög-glyph. 0°/null → nincs
/// nyíl. Az előjelet nem írjuk — azt a nyíl hordozza.
class TwaValue extends StatelessWidget {
  /// A megjelenítendő TWA, vagy null (`—`).
  const TwaValue(this.twa, {super.key});

  /// A signed TWA (`+` starboard, `−` port), vagy null.
  final Angle? twa;

  @override
  Widget build(BuildContext context) {
    final side = arrowSideFromSign(twa?.degrees);
    final number = MetricValueText(formatAngleMagnitude(twa));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: switch (side) {
        ArrowSide.right => [
          number,
          const SizedBox(width: 6),
          const Icon(Icons.arrow_left, color: starboardColor),
        ],
        ArrowSide.left => [
          const Icon(Icons.arrow_right, color: portColor),
          const SizedBox(width: 6),
          number,
        ],
        ArrowSide.none => [number],
      },
    );
  }
}
