import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';

// A mezo-alapertelmezes a temaban el (ADR 0044 D3), nem a hivohelyeken:
// ezek az assertek azt rogzitik, hogy egy sima TextFormField is a
// Foretack-alakot veszi fel, hivo-oldali dekoracio nelkul.
OutlineInputBorder _outline(InputBorder? border) {
  // A tema mind az ot border-slotot beallitja, ezert a null-ag halott; a
  // cast szandekosan dob, ha egy slot megis lemaradna.
  return border! as OutlineInputBorder;
}

void main() {
  final decoration = foretackTheme.inputDecorationTheme;
  final scheme = foretackTheme.colorScheme;

  test('fills the field with the container surface', () {
    expect(decoration.filled, isTrue);
    expect(decoration.fillColor, scheme.surfaceContainer);
  });

  test('squares every border state', () {
    final radii = [
      decoration.border,
      decoration.enabledBorder,
      decoration.focusedBorder,
      decoration.errorBorder,
      decoration.focusedErrorBorder,
    ].map((border) => _outline(border).borderRadius);

    // ADR 0044 D47: a szogletesseg a token-retegben dol el, nem a
    // hivohelyeken - ezert a temaban orizzuk.
    expect(radii, everyElement(BorderRadius.zero));
  });

  test('uses the outline tone at rest and the accent on focus', () {
    expect(_outline(decoration.enabledBorder).borderSide.color, scheme.outline);
    expect(_outline(decoration.focusedBorder).borderSide.color, scheme.primary);
  });

  test('marks both error states with the error colour', () {
    expect(_outline(decoration.errorBorder).borderSide.color, scheme.error);
    expect(
      _outline(decoration.focusedErrorBorder).borderSide.color,
      scheme.error,
    );
  });

  // A koordinata-hiba ketsoros ("Ismeretlen koordinata-formatum." mar egy
  // sorban is szoros); egy sorra vagva a felhasznalo nem latna, mi a baj.
  test('allows the error text to wrap to a second line', () {
    expect(decoration.errorMaxLines, 2);
  });
}
