import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A bundle-ölt fontok OFL-licencének regisztrálása (ADR 0041 D8).
///
/// A [LicenseRegistry] a collectort **lustán** hívja: a stream csak akkor
/// fut le, amikor valaki megnyitja a licenc-lapot, tehát az indulás
/// költsége nulla. Az OFL megköveteli a licenc és a copyright-értesítő
/// terjesztését a font-szoftverrel; ez a regisztráció teszi elérhetővé
/// az appon belül.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in _fontLicenseAssets.entries) {
      final text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}

/// Licenc-név → asset-útvonal. A kulcs jelenik meg a licenc-lapon.
const Map<String, String> _fontLicenseAssets = {
  'IBM Plex': 'assets/fonts/OFL-IBMPlex.txt',
  'Martian Mono': 'assets/fonts/OFL-MartianMono.txt',
};
