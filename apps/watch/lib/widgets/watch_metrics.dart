import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/widgets/direction_arrow.dart';

/// A nyíl-oldalhoz tartozó hajós szín: bal → port (piros), jobb → starboard
/// (zöld), nincs → `null` (a hívó nem rajzol nyilat). Egy igazságforrás a
/// phone §8.7 konvenciójával összhangban.
Color? arrowColorForSide(ArrowSide side, WatchColors colors) => switch (side) {
  ArrowSide.left => colors.port,
  ArrowSide.right => colors.starboard,
  ArrowSide.none => null,
};

/// Egy szám-érték a hozzá tartozó iránynyíllal, a szám MEGFELELŐ OLDALÁRA
/// helyezve. A `DirectionArrow` csak a glyph-et rajzolja; az elhelyezést ez az
/// atom végzi (ADR 0015, §3.5). A nyíl oldalát az `arrowSideFromSign` adja, a
/// stílusát/irányát a [kind] (TWA befelé / korrekció kifelé), a színét a hajós
/// konvenció. `ArrowSide.none` → nincs nyíl; üres [value] → csak a nyíl.
class ArrowedValue extends StatelessWidget {
  /// Létrehozza az atomot.
  const ArrowedValue({
    required this.value,
    required this.side,
    required this.kind,
    required this.colors,
    required this.valueColor,
    required this.fontSize,
    this.arrowSize = 18,
    this.arrowColor,
    super.key,
  });

  /// A megjelenített szöveg (pl. `32°`); üres is lehet (csak nyíl, pl. korrekció).
  final String value;

  /// A nyíl oldala (`arrowSideFromSign`-ból).
  final ArrowSide side;

  /// A nyíl fajtája (TWA befelé / korrekció kifelé).
  final ArrowKind kind;

  /// A téma szín-tokenjei (a nyíl hajós színéhez).
  final WatchColors colors;

  /// A szám színe.
  final Color valueColor;

  /// A szám betűmérete.
  final double fontSize;

  /// A nyíl-glyph mérete.
  final double arrowSize;

  /// Opcionális nyíl-szín-felülírás: ha megadva (pl. ambientben tompított),
  /// ez érvényes az oldal-alapú port/stbd szín helyett.
  final Color? arrowColor;

  @override
  Widget build(BuildContext context) {
    final sideColor = arrowColorForSide(side, colors);
    // none oldalnál nincs nyíl; egyébként a felülírás (ambient), különben az oldal-szín.
    final resolvedArrowColor = sideColor == null
        ? null
        : (arrowColor ?? sideColor);
    final arrow = resolvedArrowColor == null
        ? null
        : (kind == ArrowKind.twa
              ? DirectionArrow.twa(
                  side: side,
                  color: resolvedArrowColor,
                  size: arrowSize,
                )
              : DirectionArrow.correction(
                  side: side,
                  color: resolvedArrowColor,
                  size: arrowSize,
                ));
    final text = value.isEmpty
        ? null
        : Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: fontSize,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (arrow != null && side == ArrowSide.left) ...[
          arrow,
          if (text != null) const SizedBox(width: 4),
        ],
        if (text != null) text,
        if (arrow != null && side == ArrowSide.right) ...[
          if (text != null) const SizedBox(width: 4),
          arrow,
        ],
      ],
    );
  }
}

/// Egy címkézett érték-cella az óra-nézetek másodlagos sorához: kis címke
/// fölül, alatta az érték-widget (szám vagy [ArrowedValue]). A sor két cellája
/// azonos betűmérettel jelenik meg (§10.4).
class WatchMetricCell extends StatelessWidget {
  /// Létrehozza a cellát.
  const WatchMetricCell({
    required this.label,
    required this.value,
    required this.colors,
    super.key,
  });

  /// A kis címke (pl. `VMG`, `ETA`).
  final String label;

  /// Az érték-widget (a megfelelő betűmérettel adva).
  final Widget value;

  /// A téma szín-tokenjei.
  final WatchColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        value,
      ],
    );
  }
}
