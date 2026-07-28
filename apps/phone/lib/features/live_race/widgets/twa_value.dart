import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:phone/features/live_race/live_formatters.dart';
import 'package:phone/features/live_race/widgets/side_arrow.dart';

/// A TWA-érték: magnitúdó + oldal-nyíl (ARCHITECTURE §8.7, ADR 0042 D7).
///
/// A nyíl azon az oldalon áll, ahonnan a szél jön (az `Angle` előjele), és
/// BEFELÉ (a szám felé) mutat; starboard → zöld, port → piros. Tömör
/// háromszög, hogy a kormány-nyíltól elkülönüljön. 0°/null → nincs nyíl. Az
/// előjelet nem írjuk — azt a nyíl hordozza. A fokjel viszont marad
/// (ADR 0042 Addendum 1).
///
/// A [style] a hívóé (`app/foretack_typography.dart`), mert ugyanez a widget
/// szolgálja ki a 76 pt-os hero-t és a 38 pt-os kontextus-cellát is; színt a
/// stílus nem hordoz, azt a téma `onSurface`-e adja. A nyíl mérete és a rés
/// a betűmérethez kötött, hogy az arány mindkét helyen ugyanaz legyen.
class TwaValue extends StatelessWidget {
  /// A megjelenítendő TWA, vagy null (`—`).
  const TwaValue(this.twa, {required this.style, super.key});

  /// A signed TWA (`+` starboard, `−` port), vagy null.
  final Angle? twa;

  /// A szám stílusa; a nyíl ehhez méreteződik.
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final side = arrowSideFromSign(twa?.degrees);
    final fontSize = style.fontSize ?? 20;
    final gap = fontSize * 0.14;
    final arrow = SideArrow(
      side: side,
      glyph: ArrowGlyph.solid,
      size: fontSize * 0.32,
    );
    final number = Text(
      formatAngleMagnitude(twa),
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
