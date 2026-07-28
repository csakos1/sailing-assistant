import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/font_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A registry globalis, ezert minden eset tiszta lappal indul.
  setUp(LicenseRegistry.reset);

  test('registers a licence for each bundled font family', () async {
    registerFontLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    final packages = entries.expand((entry) => entry.packages).toSet();

    expect(packages, {'IBM Plex', 'Martian Mono'});
  });

  test('loads the licence text from the bundled assets', () async {
    registerFontLicenses();

    final entries = await LicenseRegistry.licenses.toList();

    // Nem csak a bejegyzes letezik: a szoveg tenylegesen betoltodott az
    // assetbol. Elgepelt asset-utvonalnal ez bukik, a fenti nem.
    for (final entry in entries) {
      expect(entry.paragraphs, isNotEmpty);
    }
  });
}
