import 'package:test/test.dart';
import 'package:web_server/src/polar_lab/fill_along_tws.dart';

void main() {
  group('fillAlongTws', () {
    test('interpolates by wind speed and anchors below toward zero', () {
      final filled = fillAlongTws([null, 6, null, 9], [2, 4, 6, 10]);

      // 2 kn: 6 x 2 / 4 = 3; 6 kn: 6 + 3 x (6 - 4) / (10 - 4) = 7
      expect(filled, [3, 6, 7, 9]);
    });

    test('holds the top value above the highest known column', () {
      expect(fillAlongTws([4, null, null], [2, 3, 4]), [4, 4, 4]);
    });

    test('keeps the known values', () {
      expect(fillAlongTws([1, 3, 2], [2, 3, 4]), [1, 3, 2]);
    });

    test('keeps an empty row empty', () {
      expect(fillAlongTws([null, null], [2, 3]), [null, null]);
    });

    test('rejects lists of different length', () {
      expect(() => fillAlongTws([1], [2, 3]), throwsArgumentError);
    });
  });
}
