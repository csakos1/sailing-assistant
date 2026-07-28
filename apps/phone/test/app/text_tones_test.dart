import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/text_tones.dart';

void main() {
  const tones = TextTones(low: Color(0xFF66788A));

  test('copyWith replaces the given field', () {
    final updated = tones.copyWith(low: const Color(0xFF112233));

    expect(updated.low, const Color(0xFF112233));
  });

  test('copyWith keeps the current value when nothing is given', () {
    expect(tones.copyWith().low, tones.low);
  });

  test('lerp reaches the other extension at t = 1', () {
    const other = TextTones(low: Color(0xFF000000));

    final mixed = tones.lerp(other, 1);

    expect(mixed.low, other.low);
  });

  test('lerp returns this for a foreign extension', () {
    // Kontraktus: idegen tipusnal nem dobunk, hanem valtozatlanul
    // maradunk -- a ThemeExtension.lerp-et a Flutter hivja, tetszoleges
    // masik extensionnel.
    expect(tones.lerp(null, 0.5), same(tones));
  });
}
