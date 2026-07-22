import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_detail/export/track_export_file_name.dart';

void main() {
  group('trackExportFileName', () {
    test('a fajlnev a prefixbol, az ISO-datumbol es a slugbol all', () {
      // Arrange / Act
      final name = trackExportFileName(
        raceName: 'Kekszalag 2026',
        startedAt: DateTime(2026, 7, 18),
      );

      // Assert
      expect(name, 'foretack-2026-07-18-kekszalag-2026.png');
    });

    test('a magyar ekezetek ASCII-ra hajlanak', () {
      // Arrange -- 'Kekszalag oszi tura' magyar ekezetekkel:
      // \u00e9 = e-acute, \u0151 = o-double-acute, \u00fa = u-acute.
      final name = trackExportFileName(
        raceName: 'K\u00e9kszalag \u0151szi t\u00fara',
        startedAt: DateTime(2026, 7, 18),
      );

      // Assert
      expect(name, 'foretack-2026-07-18-kekszalag-oszi-tura.png');
    });

    test('hianyzo startdatum eseten a datum-tag kimarad', () {
      // Arrange / Act
      final name = trackExportFileName(
        raceName: 'Kekszalag',
        startedAt: null,
      );

      // Assert
      expect(name, 'foretack-kekszalag.png');
    });

    test('a csupa irasjel nev nem hagy maga utan kotojelet', () {
      // Arrange / Act -- a slug uresre fogy, a fajlnev megis ervenyes.
      final name = trackExportFileName(
        raceName: '!!! ??? ...',
        startedAt: DateTime(2026, 7, 18),
      );

      // Assert
      expect(name, 'foretack-2026-07-18.png');
    });

    test('a tul hosszu nev csonkolodik, zaro kotojel nelkul', () {
      // Arrange -- ez a nev pont ugy csonkolodik, hogy a 40. karakter egy
      // kotojel: a naiv substring "...-ba-" alakot adna.
      final name = trackExportFileName(
        raceName: 'Balatonfured Tihany Siofok Keszthely ba korverseny',
        startedAt: null,
      );

      // Assert
      expect(name, 'foretack-balatonfured-tihany-siofok-keszthely-ba.png');

      final slug = name.substring('foretack-'.length, name.length - 4);
      expect(slug.length, lessThanOrEqualTo(40));
      expect(slug, isNot(endsWith('-')));
    });
  });
}
