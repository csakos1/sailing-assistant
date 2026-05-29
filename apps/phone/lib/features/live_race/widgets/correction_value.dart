import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/app/marine_colors.dart';
import 'package:phone/features/live_race/live_formatters.dart';
import 'package:phone/features/live_race/widgets/metric_value_text.dart';

/// A kurzus-korrekció: magnitúdó + kormány-nyíl (§8.7). A nyíl azon az
/// oldalon, amerre kormányozni kell (az `Angle` előjele), KIFELÉ (a
/// fordulás irányába) mutat; jobbra → zöld, balra → piros. Vékony
/// vonal-nyíl, hogy a TWA tömör háromszögétől elkülönüljön. 0°/null →
/// nincs nyíl.
class CorrectionValue extends StatelessWidget {
  /// A megjelenítendő korrekció, vagy null (`—`).
  const CorrectionValue(this.correction, {super.key});

  /// A signed korrekció (`+` jobbra, `−` balra), vagy null.
  final Angle? correction;

  @override
  Widget build(BuildContext context) {
    final side = arrowSideFromSign(correction?.degrees);
    final number = MetricValueText(formatAngleMagnitude(correction));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: switch (side) {
        ArrowSide.right => [
          number,
          const SizedBox(width: 6),
          const Icon(Icons.east, color: starboardColor),
        ],
        ArrowSide.left => [
          const Icon(Icons.west, color: portColor),
          const SizedBox(width: 6),
          number,
        ],
        ArrowSide.none => [number],
      },
    );
  }
}
