import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';

// A fontok a foretack_ui-bol jonnek, a phone-ban a csaladnev
// `packages/foretack_ui/<csalad>` (ADR 0047 Addendum 4 E10). Egy elgepelt
// vagy prefix nelkuli nev csendben Robotora esne vissza, es a widget-tesztek
// (Ahem font) ezt nem latjak: ez a teszt a leforditott FontManifest-ben
// keresi a harom csalad-konstanst.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every font family constant is bundled into the app', () async {
    final manifest = await rootBundle.loadString('FontManifest.json');
    final entries = jsonDecode(manifest) as List<dynamic>;
    final families = {
      for (final entry in entries)
        (entry as Map<String, dynamic>)['family'] as String,
    };

    expect(
      families,
      containsAll(<String>[
        numeralFontFamily,
        instrumentFontFamily,
        uiFontFamily,
      ]),
    );
  });
}
