import 'package:flutter/material.dart';

/// Egy kártya-cella kerete: a cella teljes téglalapja körül, befelé rajzolt
/// keret (fókusz: teal, hiba: piros; nyugalomban `BorderSide.none`).
///
/// **Miért nem `OutlineInputBorder`:** a Flutter `InputDecorator`-a egy
/// outline keretnél a szöveget 4 dp-vel (`gapPadding`) beljebb kezdi és
/// máshogy igazítja függőlegesen, mint egy nem-outline keretnél. Ha a
/// nyugalmi (`InputBorder.none`) és a fókuszos (outline) állapot típusa
/// eltér, a szöveg fókuszváltáskor elugrik (UF). Ez a keret minden
/// állapotban ugyanaz a típus (`isOutline: false`), így a szöveg helye
/// állandó, és a nyugalmi állapot egy nulla vastag változata ugyanennek.
@immutable
class CardCellBorder extends InputBorder {
  /// Keret a [borderSide] vonallal.
  const CardCellBorder({super.borderSide = BorderSide.none});

  @override
  bool get isOutline => false;

  @override
  CardCellBorder copyWith({BorderSide? borderSide}) =>
      CardCellBorder(borderSide: borderSide ?? this.borderSide);

  // A szöveg helyét nem a keret, hanem a contentPadding adja, ezért a
  // keret nem foglal helyet: így minden állapotban ugyanott áll a szöveg.
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  CardCellBorder scale(double t) =>
      CardCellBorder(borderSide: borderSide.scale(t));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect.deflate(borderSide.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is CardCellBorder) {
      return CardCellBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is CardCellBorder) {
      return CardCellBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0,
    double gapPercentage = 0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width == 0) {
      return;
    }
    // Befelé rajzolva: a vonal minden oldalon teljes vastagságban a cellán
    // belül marad, a szomszéd (kártya-keret, sín) nem takarja le.
    canvas.drawRect(rect.deflate(borderSide.width / 2), borderSide.toPaint());
  }

  @override
  bool operator ==(Object other) =>
      other is CardCellBorder && other.borderSide == borderSide;

  @override
  int get hashCode => borderSide.hashCode;
}
