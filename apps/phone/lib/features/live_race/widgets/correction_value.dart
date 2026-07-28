import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/features/live_race/live_formatters.dart';
import 'package:phone/features/live_race/widgets/side_arrow.dart';

/// A kurzus-korrekció: magnitúdó + kormány-nyíl (ARCHITECTURE §8.7,
/// ADR 0042 D7).
///
/// A nyíl azon az oldalon áll, amerre kormányozni kell (az `Angle` előjele),
/// és KIFELÉ (a fordulás irányába) mutat; jobbra → zöld, balra → piros.
/// Vékony vonal-nyíl, hogy a TWA tömör háromszögétől elkülönüljön.
/// 0°/null → nincs nyíl.
///
/// A `jobbra` / `balra` kísérőszöveg **nem** ezé a widgeté: az a cella
/// `support` rekeszébe megy, a `FittedBox`-on kívülre, hogy ne kicsinyítse
/// le a számot (ADR 0042 D4).
class CorrectionValue extends StatelessWidget {
  /// A megjelenítendő korrekció, vagy null (`—`).
  const CorrectionValue(this.correction, {required this.style, super.key});

  /// A signed korrekció (`+` jobbra, `−` balra), vagy null.
  final Angle? correction;

  /// A szám stílusa; a nyíl ehhez méreteződik.
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final side = arrowSideFromSign(correction?.degrees);
    final fontSize = style.fontSize ?? 20;
    final gap = fontSize * 0.16;
    final arrow = SideArrow(
      side: side,
      glyph: ArrowGlyph.line,
      size: fontSize * 0.36,
    );
    final number = Text(
      formatAngleMagnitude(correction),
      maxLines: 1,
      style: style.copyWith(color: Theme.of(context).colorScheme.onSurface),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: switch (side) {
        ArrowSide.right => [number, SizedBox(width: gap), arrow],
        ArrowSide.left => [arrow, SizedBox(width: gap), number],
        ArrowSide.none => [number],
      },
    );
  }
}
