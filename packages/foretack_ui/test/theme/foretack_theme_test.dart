import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';

// Smoke-teszt a tema-epitore (ADR 0047 Addendum 4 E11): a widgetek a
// harom extensiont `!`-lel olvassak, ezert egy kimaradt regisztracio
// futasideju hiba lenne, nem csak rossz szin.
void main() {
  test('registers every theme extension the widgets read', () {
    expect(foretackTheme.extension<ConfidenceColors>(), isNotNull);
    expect(foretackTheme.extension<WarningColors>(), isNotNull);
    expect(foretackTheme.extension<TextTones>(), isNotNull);
  });

  test('sets the package-qualified UI font family app-wide', () {
    expect(foretackTheme.textTheme.bodyMedium?.fontFamily, uiFontFamily);
    expect(uiFontFamily, startsWith('packages/foretack_ui/'));
  });

  test('keeps the marine dark brightness', () {
    expect(foretackTheme.colorScheme.brightness, Brightness.dark);
  });
}
