import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/auth/sign_in/qr_module_layout.dart';

void main() {
  test('uses whole-pixel modules and centres the grid', () {
    // ACT: 57 modul (10-es verzio) a 264 px-es mezoben, 16 px zonaval
    final layout = qrModuleLayout(
      extent: 264,
      moduleCount: 57,
      quietZone: 16,
    );

    // ASSERT: 232 / 57 = 4,07 -> 4 px; a racs 228 px, a maradek 36 px
    expect(layout.moduleSize, 4);
    expect(layout.offset, 18);
  });

  test('keeps at least the quiet zone on an uneven remainder', () {
    // ACT: 25 modul: 232 / 25 = 9,28 -> 9 px, a racs 225 px
    final layout = qrModuleLayout(
      extent: 264,
      moduleCount: 25,
      quietZone: 16,
    );

    // ASSERT: a 39 px maradek kettevagva 19,5 -> 19, egesz pixelen
    expect(layout.moduleSize, 9);
    expect(layout.offset, 19);
    expect(layout.offset, greaterThanOrEqualTo(16));
    expect(264 - layout.offset - 25 * layout.moduleSize, greaterThan(16));
  });
}
